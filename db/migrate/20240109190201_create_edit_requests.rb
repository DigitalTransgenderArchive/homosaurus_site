class CreateEditRequests < ActiveRecord::Migration[5.2]
  TRChange = Struct.new(:lang, :data)
  # additions is in the form [[field1, pos1, newval1],...]
  # removals is in the form [[field1, pos1],...]
  def self.modify_edit_request(er, removals, additions, changes)
    removals.each do |r|
      er.my_changes[r[0]].delete_at(r[1])
    end
    additions.each do |a|
      er.my_changes[a[0]].insert(a[1], a[2])
    end    
    changes.each do |c|
      er.my_changes[c[0]] = c[1]
    end
    er.save!
  end

  # given edit request, modify it to use the correct label. Create and return an edit request.
  def self.change_original_pref_label(er, change_time, correct_label, version_release_id)
    old_label = er.my_changes[Relation::Pref_label][0][2]

    er.my_changes[Relation::Pref_label][0][2] = correct_label
    er.save!
    new_er =  EditRequest::makeEmptyER(er.term_id, change_time, version_release_id, "Published", er.my_changes.uri, er.my_changes.identifier)
    
    new_er.my_changes[Relation::Pref_label].insert(0, ["-", "en", correct_label])
    new_er.my_changes[Relation::Pref_label].insert(0, ["+", "en", old_label])
    new_er.save!
    return new_er
  end

  # Migrates a version's terms created within a certain period and stores as a version_release_id
  def self.migrate_term_creations(vocab_id, version_string, version_id, start_date, end_date)
    terms = Term.where('vocabulary_id = ' + vocab_id.to_s + \
                       ' AND DATE_FORMAT(created_at, "%Y-%m-%d") > "' + start_date + '"' + \
                       ' AND DATE_FORMAT(created_at, "%Y-%m-%d") < "' + end_date + '" ').order(:pref_label)
    say_with_time "Migrating Term Creations V. #{version_string} (#{terms.count()} terms)" do
      i = 1
      terms.each do |t|
        # puts ("  - " +  ("%.4d" % "#{i}") + " - " + ("%.5d" % "#{t.id}") + ":  #{t.pref_label}")
        EditRequest.makeFromTerm(t.id, version_id) 
        i += 1
      end
      p "Completed Migration: Term Creations V. #{version_string} (#{terms.count()} terms)"
    end
  end

  # Special function to handle 3.0 migration
  def self.migrate_term_creations_v_3_0()
    say_with_time "Migrating Term Creations V. 3.0" do
      i = 0
      EditRequest.where("version_release_id >= 2").each do |er|
        t = Term.find_by(id: er.term_id)
        redirects_to = t.term_relationships.find_by(relation_id: Relation::Replaced_by).data
        new_t = Term.find_by(id: redirects_to)
        if er.previous()
          next
        end
        new_er = EditRequest::makeEmptyER(redirects_to, Time.new(2019, 9, 1, 0, 0, 0),
                                          6, "Published", new_t.uri, new_t.identifier)
        new_er.prev_term_id = t.id

        # No longer used in V3
        t.term_relationships.where(relation_id: [Relation::Close_match, Relation::Exact_match]).each do |tr|
          new_er.my_changes[tr.relation_id] << ["-", nil, tr.data]
        end

        # Remove non-term values dropped in V3
        t.term_relationships.where(relation_id: [Relation::Alt_label, Relation::Lcsh_exact, Relation::Lcsh_close]).each do |tr|
          # p "Comparing (#{new_t.uri}) [#{tr.relation_id}] -- #{tr.language_id} -- #{tr.data}"
          # pp new_t.term_relationships.where(relation_id: tr.relation_id).where(language_id: tr.language_id).where("BINARY data = ?", tr.data)
          unless new_t.term_relationships.where(relation_id: tr.relation_id).where(language_id: tr.language_id).where("BINARY data = ?", tr.data).count > 0
            new_er.my_changes[tr.relation_id] << ["-", tr.language_id, tr.data]
          end
        end

        # Remove term links dropped in V3
        t.term_relationships.where(relation_id: [Relation::Related, Relation::Broader, Relation::Narrower]).each do |tr|
          replaced_by = Term.find_by(uri:Term.find_by(id: tr.data).is_replaced_by).id
          unless new_t.term_relationships.where(relation_id: tr.relation_id).where(data: replaced_by.to_s).count > 0
            new_er.my_changes[tr.relation_id] << ["-", tr.language_id, tr.data]
          end
        end

        # For all relations 
        Relation.pluck(:id).each do |r|
          next if r == Relation::Redirects_to #or r == Relation::Pref_label
          if r == Relation::Pref_label
            v2_pref_label = t.term_relationships.find_by(relation_id: Relation::Pref_label)
            v3_pref_label = new_t.term_relationships.find_by(relation_id: Relation::Pref_label)
            unless (v2_pref_label.data == v3_pref_label.data and v2_pref_label.language_id == v3_pref_label.language_id) or v3_pref_label.data.include? "LGBTQ+" or v3_pref_label.data.include? "affirming surgery"
              new_er.my_changes[r] << ["-", v2_pref_label.language_id, v2_pref_label.data]
              new_er.my_changes[r] << ["+", v3_pref_label.language_id, v3_pref_label.data]
            end
            next
          end
          if r == Relation::Description and t.description and t.description != new_t.description and t.description != ""
            new_er.my_changes[r] << ["-", "en", t.description]
            # elsif r == Relation::Pref_label and new_t.pref_label != t.pref_label
            #   new_er.my_changes[r] << ["-", "en", t.pref_label]
          end
          new_t.term_relationships.where(relation_id: r).each do |tr|
            if [Relation::Broader, Relation::Narrower, Relation::Related, Relation::Close_match, Relation::Exact_match].include? r
              replaces = Term.find_by(id: tr.data).replaces
              if replaces
                new_er.my_changes[r] << ["-", nil, Term.find_by(uri: Term.find_by(id: tr.data).replaces).id.to_s]
              end
              new_er.my_changes[r] << ["+", nil, tr.data]
            else
              #p "Comparing (#{new_t.uri}) [#{r}] -- #{tr.language_id} -- #{tr.data}"
              #pp t.term_relationships.where(relation_id: r).where(language_id: tr.language_id).where("BINARY data = ?", tr.data)
              unless t.term_relationships.where(relation_id: r).where(language_id: tr.language_id).where("BINARY data = ?", tr.data).count > 0
                new_er.my_changes[r] << ["+", tr.language_id, tr.data]
              end
            end
          end
        end
        #pp new_er
        #new_er.my_changes[1] = [["+", "en", new_t.description]]
        new_er.save!
        i += 1
      end
      p "Completed Migration: Term Creations V. 3.0 (#{i} terms)"
    end
  end

  # Handle additions changes particular to certain version releases
  def self.sanitize_v_2_3_migration()
    # Modify edit requests from 2.2 
    CreateEditRequests::modify_edit_request(Term.find_by(id: 2046).edit_requests[0],
                                            [ [Relation::Pref_label, 0] ],
                                            [ [Relation::Pref_label, 0, ["+", "en", "Assigned female"] ],
                                              [Relation::Alt_label, 1, ["+", "en", "Assigned female at birth"]] ],
                                            [ ["uri", "http://homosaurus.org/v2/assignedFemale"],
                                              ["identifier", "assignedFemale"] ])
    CreateEditRequests::modify_edit_request(Term.find_by(id: 2048).edit_requests[0],
                                            [ [Relation::Pref_label, 0] ],
                                            [ [Relation::Pref_label, 0, ["+", "en", "Assigned male"]],
                                              [Relation::Alt_label, 1, ["+", "en", "Assigned male at birth"]] ],
                                            [ ["uri", "http://homosaurus.org/v2/assignedMale"],
                                              ["identifier", "assignedMale"] ])
    CreateEditRequests::modify_edit_request(Term.find_by(id: 2291).edit_requests[0],
                                            [ [Relation::Pref_label, 0], [Relation::Alt_label, 0] ],
                                            [ [Relation::Pref_label, 0, ["+", "en", "Culturally-specific gender identities"]] ],
                                            [ ["uri", "http://homosaurus.org/v2/culturallySpecificGenderIdentities"],
                                              ["identifier", "culturallySpecificGenderIdentities"]])

    # Add changes from 2.3
    time = Term.find_by(id: 3617).created_at
    #EditRequest.makeFromTerm(t.id, version_id)
    er = EditRequest::makeEmptyER(2046, time, 5)
    CreateEditRequests::modify_edit_request(er, [],
                                            [ [Relation::Pref_label, 0, ["-", "en", "Assigned female"]],
                                              [Relation::Pref_label, 0, ["+", "en", "Assigned female at birth"]],
                                              [Relation::Alt_label, 0, ["-", "en", "Assigned female at birth"]]],
                                            [ ["uri", "http://homosaurus.org/v2/assignedFemaleAtBirth"],
                                              ["identifier", "assignedFemaleAtBirth"] ])
    er = EditRequest::makeEmptyER(2048, time, 5)
    CreateEditRequests::modify_edit_request(er, [],
                                            [ [Relation::Pref_label, 0, ["-", "en", "Assigned male"]],
                                              [Relation::Pref_label, 0, ["+", "en", "Assigned male at birth"]],
                                              [Relation::Alt_label, 0, ["-", "en", "Assigned male at birth"]]],
                                            [ ["uri", "http://homosaurus.org/v2/assignedMaleAtBirth"],
                                              ["identifier", "assignedMaleAtBirth"] ])
    er = EditRequest::makeEmptyER(2291, time, 5)
    CreateEditRequests::modify_edit_request(er, [],
                                            [ [Relation::Pref_label, 0, ["-", "en", "Culturally-specific gender identities"]],
                                              [Relation::Pref_label, 0, ["+", "en", "Non-Euro-American gender and sexual identities"]],
                                              [Relation::Alt_label, 0, ["+", "en", "Culturally-specific gender identities"]]],
                                            [ ["uri", "http://homosaurus.org/v2/nonEuroAmericanGenderAndSexualIdentities"],
                                              ["identifier", "nonEuroAmericanGenderAndSexualIdentities"] ])
  end

  def self.sanitize_v_3_1_migration()
    # Nudes -> Nude art
    change_time = Term.find_by(id: 5475).created_at
    
    er = EditRequest::makeEmptyER(4737, change_time, 7)
    CreateEditRequests::modify_edit_request(er, [], [
                                              [Relation::Pref_label, 0, ["-", "en", "Nudes"]],
                                              [Relation::Pref_label, 0, ["+", "en", "Nude art"]]], [])


    # (LGBTQ -> LGBTQ+) && ([Term] (LGBTQ) -> LGBTQ+ Term)

    v_3_1_changes = {
      "homoit0000530" => "LGBTQ+-affirming religious groups",
      "homoit0000059" => "Anti-LGBTQ+ violence",
      "homoit0000068" => "Arrests of LGBTQ+ people",
      "homoit0000226" => "Buddy care for LGBTQ+ people",
      "homoit0000260" => "Children of LGBTQ+ people",
      "homoit0000843" => "Conception by LGBTQ+ people",
      "homoit0000348" => "Detention of LGBTQ+ people",
      "homoit0000349" => "Detention of LGBTQ+ people under a hospital order",
      "homoit0000614" => "Health care for LGBTQ+ people",
      "homoit0000112" => "Intolerance towards LGBTQ+ people",
      "homoit0000002" => "LGBTQ+ Aboriginal people",
      "homoit0000808" => "LGBTQ+ action campaigns",
      "homoit0000006" => "LGBTQ+ activism",
      "homoit0000007" => "LGBTQ+ activists",
      "homoit0000008" => "LGBTQ+ actors",
      "homoit0000809" => "LGBTQ+ adoption",
      "homoit0000810" => "LGBTQ+ adoptive families",
      "homoit0000811" => "LGBTQ+ adoptive parenthood",
      "homoit0000812" => "LGBTQ+ adoptive parents",
      "homoit0000813" => "LGBTQ+ African religions",
      "homoit0000015" => "LGBTQ+ African-Americans",
      "homoit0000016" => "LGBTQ+ Afro-Canadians",
      "homoit0000017" => "LGBTQ+ Afro-Caribbeans",
      "homoit0000018" => "LGBTQ+ Afro-Europeans",
      "homoit0000019" => "LGBTQ+ Afro-Latin Americans",
      "homoit0001540" => "LGBTQ+ alcoholics",
      "homoit0000048" => "LGBTQ+ Anglicans",
      "homoit0000066" => "LGBTQ+ archives",
      "homoit0000815" => "LGBTQ+ art censorship",
      "homoit0000070" => "LGBTQ+ artists",
      "homoit0000816" => "LGBTQ+ arts",
      "homoit0000817" => "LGBTQ+ Asian religions",
      "homoit0000073" => "LGBTQ+ Asian-Americans",
      "homoit0000074" => "LGBTQ+ Asians",
      "homoit0000082" => "LGBTQ+ atheists",
      "homoit0000818" => "LGBTQ+ awards",
      "homoit0000097" => "LGBTQ+ Baptists",
      "homoit0000100" => "LGBTQ+ bars",
      "homoit0000104" => "LGBTQ+ beaches",
      "homoit0001614" => "LGBTQ+ biographies",
      "homoit0000819" => "LGBTQ+ biological parents",
      "homoit0000820" => "LGBTQ+ biracial people",
      "homoit0000821" => "LGBTQ+ birth parents",
      "homoit0000208" => "LGBTQ+ Black people",
      "homoit0000822" => "LGBTQ+ blind people",
      "homoit0000823" => "LGBTQ+ blogs",
      "homoit0000824" => "LGBTQ+ blood donors",
      "homoit0000825" => "LGBTQ+ book censorship",
      "homoit0000826" => "LGBTQ+ book clubs",
      "homoit0000827" => "LGBTQ+ books",
      "homoit0000216" => "LGBTQ+ bookshops",
      "homoit0000225" => "LGBTQ+ Buddhists",
      "homoit0000237" => "LGBTQ+ Calvinists",
      "homoit0000828" => "LGBTQ+ cartoons",
      "homoit0000829" => "LGBTQ+ censorship",
      "homoit0000830" => "LGBTQ+ centers",
      "homoit0000831" => "LGBTQ+ challenged books",
      "homoit0000249" => "LGBTQ+ characters",
      "homoit0000832" => "LGBTQ+ chatrooms",
      "homoit0000256" => "LGBTQ+ children",
      "homoit0001541" => "LGBTQ+ children of alcoholics",
      "homoit0000833" => "LGBTQ+ choruses",
      "homoit0000834" => "LGBTQ+ chosen families",
      "homoit0000265" => "LGBTQ+ Christians",
      "homoit0000835" => "LGBTQ+ civil disobedience",
      "homoit0000276" => "LGBTQ+ civil rights",
      "homoit0001624" => "LGBTQ+ clergy",
      "homoit0000836" => "LGBTQ+ clubs",
      "homoit0000837" => "LGBTQ+ co-fathers",
      "homoit0000838" => "LGBTQ+ co-mothers",
      "homoit0000839" => "LGBTQ+ co-parenthood",
      "homoit0000840" => "LGBTQ+ co-parents",
      "homoit0000841" => "LGBTQ+ comics",
      "homoit0000842" => "LGBTQ+ communes",
      "homoit0000297" => "LGBTQ+ communities",
      "homoit0000298" => "LGBTQ+ community centers",
      "homoit0000300" => "LGBTQ+ Confucianists",
      "homoit0000844" => "LGBTQ+ conscientious objection",
      "homoit0000310" => "LGBTQ+ couples",
      "homoit0000845" => "LGBTQ+ cruises",
      "homoit0000846" => "LGBTQ+ dating applications",
      "homoit0000847" => "LGBTQ+ dating websites",
      "homoit0000330" => "LGBTQ+ daughters",
      "homoit0000337" => "LGBTQ+ deaf people",
      "homoit0000848" => "LGBTQ+ death and dying",
      "homoit0000849" => "LGBTQ+ death notices",
      "homoit0000850" => "LGBTQ+ defamation campaigns",
      "homoit0000851" => "LGBTQ+ demonstrations",
      "homoit0000853" => "LGBTQ+ direct action",
      "homoit0000356" => "LGBTQ+ discrimination",
      "homoit0000854" => "LGBTQ+ divorce",
      "homoit0000855" => "LGBTQ+ domestic violence",
      "homoit0000363" => "LGBTQ+ dominatrices",
      "homoit0000376" => "LGBTQ+ drama",
      "homoit0000386" => "LGBTQ+ Eastern Orthodox Christians",
      "homoit0000857" => "LGBTQ+ emancipation",
      "homoit0000858" => "LGBTQ+ emotions",
      "homoit0000859" => "LGBTQ+ erotic literature",
      "homoit0000860" => "LGBTQ+ ethnic groups",
      "homoit0000861" => "LGBTQ+ events",
      "homoit0000863" => "LGBTQ+ ex-partners",
      "homoit0000420" => "LGBTQ+ families",
      "homoit0000864" => "LGBTQ+ family planning",
      "homoit0000865" => "LGBTQ+ fantasy fiction",
      "homoit0000866" => "LGBTQ+ fatherhood",
      "homoit0000443" => "LGBTQ+ fiction",
      "homoit0000867" => "LGBTQ+ film censorship",
      "homoit0000868" => "LGBTQ+ film festivals",
      "homoit0000869" => "LGBTQ+ films",
      "homoit0000870" => "LGBTQ+ foster families",
      "homoit0000871" => "LGBTQ+ foster parenthood",
      "homoit0000872" => "LGBTQ+ foster parents",
      "homoit0000873" => "LGBTQ+ friendliness",
      "homoit0000874" => "LGBTQ+ graphic novels",
      "homoit0000876" => "LGBTQ+ health care centers",
      "homoit0000877" => "LGBTQ+ health education",
      "homoit0000633" => "LGBTQ+ Hindus",
      "homoit0000878" => "LGBTQ+ historical terms",
      "homoit0000879" => "LGBTQ+ homeless people",
      "homoit0000880" => "LGBTQ+ homeless youth",
      "homoit0001580" => "LGBTQ+ horror fiction",
      "homoit0000881" => "LGBTQ+ hotels",
      "homoit0000883" => "LGBTQ+ immigration rights",
      "homoit0000884" => "LGBTQ+ imprisonment",
      "homoit0000885" => "LGBTQ+ incest victims",
      "homoit0000886" => "LGBTQ+ indigenous people",
      "homoit0000660" => "LGBTQ+ information centers",
      "homoit0000888" => "LGBTQ+ Internet forums",
      "homoit0000889" => "LGBTQ+ intimacy",
      "homoit0000676" => "LGBTQ+ Inuit",
      "homoit0000680" => "LGBTQ+ Jehovah's Witnesses",
      "homoit0000682" => "LGBTQ+ Jews",
      "homoit0000890" => "LGBTQ+ Judaism",
      "homoit0000253" => "LGBTQ+ Latinx",
      "homoit0000968" => "LGBTQ+ libraries",
      "homoit0000891" => "LGBTQ+ literary awards",
      "homoit0001602" => "LGBTQ+ literary criticism",
      "homoit0000892" => "LGBTQ+ literary salons",
      "homoit0000972" => "LGBTQ+ literature",
      "homoit0000893" => "LGBTQ+ lobbying",
      "homoit0000894" => "LGBTQ+ love",
      "homoit0000895" => "LGBTQ+ lovers",
      "homoit0000896" => "LGBTQ+ magazines",
      "homoit0000897" => "LGBTQ+ manga",
      "homoit0000899" => "LGBTQ+ marketing",
      "homoit0000999" => "LGBTQ+ masters",
      "homoit0000900" => "LGBTQ+ meeting places",
      "homoit0000901" => "LGBTQ+ memorials",
      "homoit0000902" => "LGBTQ+ migrants",
      "homoit0001018" => "LGBTQ+ mistresses",
      "homoit0000904" => "LGBTQ+ Mormons",
      "homoit0000905" => "LGBTQ+ motherhood",
      "homoit0000906" => "LGBTQ+ motorcycle clubs",
      "homoit0001026" => "LGBTQ+ movement",
      "homoit0000903" => "LGBTQ+ multi-racial people",
      "homoit0001030" => "LGBTQ+ museums",
      "homoit0000907" => "LGBTQ+ museums",
      "homoit0000908" => "LGBTQ+ musicians",
      "homoit0001032" => "LGBTQ+ Muslims",
      "homoit0000852" => "LGBTQ+ mystery and detective fiction",
      "homoit0000814" => "LGBTQ+ Native American religions",
      "homoit0001037" => "LGBTQ+ Native Americans",
      "homoit0000558" => "LGBTQ+ neighborhoods",
      "homoit0001041" => "LGBTQ+ newsletters",
      "homoit0001042" => "LGBTQ+ newspapers",
      "homoit0000909" => "LGBTQ+ night life",
      "homoit0000910" => "LGBTQ+ nonviolent resistance",
      "homoit0000911" => "LGBTQ+ obituaries",
      "homoit0000912" => "LGBTQ+ Old Catholic Church",
      "homoit0000393" => "LGBTQ+ older people",
      "homoit0000856" => "LGBTQ+ older people's organizations",
      "homoit0001069" => "LGBTQ+ Pagans",
      "homoit0000913" => "LGBTQ+ Papuans",
      "homoit0000914" => "LGBTQ+ parenthood",
      "homoit0001075" => "LGBTQ+ parents",
      "homoit0001083" => "LGBTQ+ partners",
      "homoit0001542" => "LGBTQ+ partners of alcoholics",
      "homoit0000915" => "LGBTQ+ people",
      "homoit0001543" => "LGBTQ+ people in Adult Children of Alcoholics",
      "homoit0001544" => "LGBTQ+ people in Al-Anon",
      "homoit0001545" => "LGBTQ+ people in Alcoholics Anonymous",
      "homoit0001546" => "LGBTQ+ people in Cocaine Anonymous",
      "homoit0001547" => "LGBTQ+ people in Crystal Meth Anonymous",
      "homoit0001548" => "LGBTQ+ people in Narcotics Anonymous",
      "homoit0001549" => "LGBTQ+ people in recovery",
      "homoit0001100" => "LGBTQ+ people in the military",
      "homoit0001101" => "LGBTQ+ people of color",
      "homoit0001550" => "LGBTQ+ people with addictions",
      "homoit0000916" => "LGBTQ+ people with physical disabilities",
      "homoit0000917" => "LGBTQ+ people with visual disabilities",
      "homoit0001108" => "LGBTQ+ persecutions",
      "homoit0000918" => "LGBTQ+ personal and family law",
      "homoit0000919" => "LGBTQ+ petitions",
      "homoit0000920" => "LGBTQ+ phobia",
      "homoit0000921" => "LGBTQ+ platonic love",
      "homoit0000922" => "LGBTQ+ plays",
      "homoit0001118" => "LGBTQ+ poetry",
      "homoit0000013" => "LGBTQ+ porn films",
      "homoit0000923" => "LGBTQ+ porn magazines",
      "homoit0001132" => "LGBTQ+ press",
      "homoit0000887" => "LGBTQ+ prisoners",
      "homoit0000924" => "LGBTQ+ prisoners of conscience",
      "homoit0001137" => "LGBTQ+ Protestants",
      "homoit0001144" => "LGBTQ+ publishers",
      "homoit0000925" => "LGBTQ+ pubs",
      "homoit0000926" => "LGBTQ+ Quakers",
      "homoit0001231" => "LGBTQ+ radio",
      "homoit0001551" => "LGBTQ+ recovery groups",
      "homoit0000927" => "LGBTQ+ refugees",
      "homoit0001237" => "LGBTQ+ relationships",
      "homoit0000928" => "LGBTQ+ religions",
      "homoit0000929" => "LGBTQ+ resorts",
      "homoit0000930" => "LGBTQ+ restaurants",
      "homoit0000931" => "LGBTQ+ retirement homes",
      "homoit0000932" => "LGBTQ+ riots",
      "homoit0000875" => "LGBTQ+ Roma",
      "homoit0001244" => "LGBTQ+ Roman Catholics",
      "homoit0001586" => "LGBTQ+ romance fiction",
      "homoit0000934" => "LGBTQ+ science fiction",
      "homoit0000935" => "LGBTQ+ self-defense",
      "homoit0000936" => "LGBTQ+ self-repression",
      "homoit0000937" => "LGBTQ+ separation",
      "homoit0001277" => "LGBTQ+ sex workers",
      "homoit0000938" => "LGBTQ+ sexual abuse",
      "homoit0000939" => "LGBTQ+ shamans",
      "homoit0000940" => "LGBTQ+ Shintoists",
      "homoit0001608" => "LGBTQ+ short stories",
      "homoit0000941" => "LGBTQ+ single fathers",
      "homoit0000942" => "LGBTQ+ single mothers",
      "homoit0000943" => "LGBTQ+ single parent families",
      "homoit0000944" => "LGBTQ+ single parents",
      "homoit0001317" => "LGBTQ+ slang",
      "homoit0000946" => "LGBTQ+ social media",
      "homoit0000945" => "LGBTQ+ social parenthood",
      "homoit0000947" => "LGBTQ+ social processes",
      "homoit0001329" => "LGBTQ+ sons",
      "homoit0000948" => "LGBTQ+ spirituality",
      "homoit0000949" => "LGBTQ+ sporting events",
      "homoit0000950" => "LGBTQ+ sports clubs",
      "homoit0001552" => "LGBTQ+ step work",
      "homoit0000951" => "LGBTQ+ students' clubs",
      "homoit0000952" => "LGBTQ+ suicide",
      "homoit0000953" => "LGBTQ+ support groups",
      "homoit0001349" => "LGBTQ+ survivors of hate crimes",
      "homoit0001350" => "LGBTQ+ survivors of rape",
      "homoit0001351" => "LGBTQ+ survivors of sexual abuse",
      "homoit0001352" => "LGBTQ+ survivors of war",
      "homoit0000954" => "LGBTQ+ symbols",
      "homoit0000955" => "LGBTQ+ Taoists",
      "homoit0001359" => "LGBTQ+ television",
      "homoit0001363" => "LGBTQ+ theater",
      "homoit0001364" => "LGBTQ+ theology",
      "homoit0000956" => "LGBTQ+ tourism",
      "homoit0000957" => "LGBTQ+ unrequited love",
      "homoit0000862" => "LGBTQ+ veterans",
      "homoit0000312" => "LGBTQ+ victims of crime",
      "homoit0000613" => "LGBTQ+ victims of hate crimes",
      "homoit0000958" => "LGBTQ+ victims of rape",
      "homoit0000959" => "LGBTQ+ victims of sexual abuse",
      "homoit0000961" => "LGBTQ+ victims of war",
      "homoit0001492" => "LGBTQ+ victims' rights",
      "homoit0000960" => "LGBTQ+ visibility",
      "homoit0000962" => "LGBTQ+ websites",
      "homoit0000963" => "LGBTQ+ weddings",
      "homoit0000243" => "LGBTQ+ white people",
      "homoit0001521" => "LGBTQ+ youth",
      "homoit0000964" => "LGBTQ+ youth centers",
      "homoit0001522" => "LGBTQ+ youth literature",
      "homoit0000965" => "LGBTQ+ zines",
      "homoit0001012" => "Mental health care for LGBTQ+ people",
      "homoit0000641" => "Murders of LGBTQ+ people",
      "homoit0001113" => "Physical health care for LGBTQ+ people",
      "homoit0000933" => "Schools for LGBTQ+ youth",
      "homoit0001307" => "Sexually abused LGBTQ+ children",
      "homoit0001348" => "Survivors of anti-LGBTQ+ violence",
      "homoit0001482" => "Undocumented LGBTQ+ residents"
    }

    
    # EditRequest.where(version_release_id: 6).each do |er|
    say_with_time "Completed Term Pref. Label Changes V. 3.1" do
      v_3_1_changes.each do |identifier, pref_label|
        #p "#{identifier}  --  #{pref_label}"
        t =  Term.find_by(identifier: identifier)
        er = t.edit_requests[0]
        next unless (er and er.version_release_id == 6)  # skip 3.1 term creations
        prev_term = Term.find_by(id: er.prev_term_id)
        label_lang = t.pref_label_language.split("@")[1]
        #CreateEditRequests::modify_edit_request(er, [[4, 0]], [], [[2, [["+", "en", prev_term.pref_label]]]])
        new_er = EditRequest::makeEmptyER(er.term_id, change_time, 7, "Published", t.uri, t.identifier)
        CreateEditRequests::modify_edit_request(new_er, [], [], [[Relation::Pref_label, [
                                                                    ["-", "en", prev_term.pref_label],
                                                                    ["+", label_lang, pref_label]]]])

        er.my_changes[Relation::Alt_label].each do |r|
          val = r[2]
          correct_val = r[2].sub "LGBTQ+", "LGBTQ"
          if correct_val != val
            r[2] = correct_val
            new_er.my_changes[Relation::Alt_label] << ['-', r[1], correct_val]
            new_er.my_changes[Relation::Alt_label] << ['+', r[1], val]
          end
        end
        new_er.save!
        er.save!
      end
    end
  end

  def self.sanitize_v_3_2_migration()
    change_time = Term.find_by(id: 4246).updated_at
    v_3_2_changes = [
      ["homoit0000561", "Gender confirming surgery", "Gender affirming surgery"],
      ["homoit0000569", "Genderfluid", "Genderfluid identity"],
      ["homoit0000584", "Genital reconstruction surgery", "Bottom surgery"],
      ["homoit0001866", "LGBTQ+ deaf people", "LGBTQ+ Deaf people"],
      ["homoit0000879", "LGBTQ+ homeless people", "LGBTQ+ unhoused people"],
      ["homoit0000880", "LGBTQ+ homeless youth", "LGBTQ+ unhoused youth"],
      ["homoit0001670", "Xenogender", "Xenogender identity"],
      ["homoit0000123", "Bisexual African-Americans", "African American bisexual people"],
      ["homoit0000124", "Bisexual Afro-Canadians", "Afro-Canadian bisexual people"],
      ["homoit0000125", "Bisexual Afro-Caribbeans", "Afro-Caribbean bisexual people"],
      ["homoit0000126", "Bisexual Afro-Europeans", "Afro-European bisexual people"],
      ["homoit0000127", "Bisexual Afro-Latin Americans", "Afro-Latin American bisexual people"],
      ["homoit0000130", "Bisexual Asian Americans", "Asian American bisexual people"],
      ["homoit0000131", "Bisexual Asians", "Asian bisexual people"],
      ["homoit0001798", "Bisexual biracial people", "Biracial bisexual people"],
      ["homoit0000135", "Bisexual Black people", "Black bisexual people"],
      ["homoit0000155", "Bisexual Latinx", "Latino/a/x bisexual people"],
      ["homoit0001803", "Bisexual multi-racial people", "Multiracial bisexual people"],
      ["homoit0000165", "Bisexual Native Americans", "Native American bisexual people"],
      ["homoit0000201", "Bisexual White people", "White bisexual people"],
      ["homoit0000463", "Gay African-Americans", "African American gay men"],
      ["homoit0000464", "Gay Afro-Canadians", "Afro-Canadian gay men"],
      ["homoit0000465", "Gay Afro-Caribbeans", "Afro-Caribbean gay men"],
      ["homoit0000466", "Gay Afro-Europeans", "Afro-European gay men"],
      ["homoit0000467", "Gay Afro-Latin Americans", "Afro-Latin American gay men"],
      ["homoit0000471", "Gay Asian Americans", "Asian American gay men"],
      ["homoit0000472", "Gay Asians", "Asian gay men"],
      ["homoit0001797", "Gay biracial people", "Biracial gay men"],
      ["homoit0000477", "Gay Black people", "Black gay men"],
      ["homoit0000498", "Gay Latinx", "Latino/a/x gay men"],
      ["homoit0001802", "Gay multi-racial people", "Multiracial gay men"],
      ["homoit0000513", "Gay Native Americans change to", "Native American gay men"],
      ["homoit0000555", "Gay White people", "White gay men"],
      ["homoit0000714", "Lesbian African-Americans", "African American lesbians"],
      ["homoit0000715", "Lesbian Afro-Canadians", "Afro-Canadian lesbians"],
      ["homoit0000716", "Lesbian Afro-Caribbeans", "Afro-Carribbean lesbians"],
      ["homoit0000717", "Lesbian Afro-Europeans", "Afro-European lesbians"],
      ["homoit0000718", "Lesbian Afro-Latin Americans", "Afro-Latin American lesbians"],
      ["homoit0000721", "Lesbian Asian Americans", "Asian American lesbians"],
      ["homoit0000722", "Lesbian Asians", "Asian lesbians"],
      ["homoit0001796", "Lesbian biracial people", "Biracial lesbians"],
      ["homoit0000726", "Lesbian Black people", "Black lesbians"],
      ["homoit0000747", "Lesbian Latinx", "Latino/a/x lesbians"],
      ["homoit0001801", "Lesbian multi-racial people", "Multiracial lesbians"],
      ["homoit0000758", "Lesbian Native Americans", "Native American lesbians"],
      ["homoit0000797", "Lesbian White people", "White lesbians"],
      ["homoit0000002", "LGBTQ+ Aboriginal people", "Aboriginal Australian LGBTQ+ people"],
      ["homoit0000015", "LGBTQ+ African-Americans", "African American LGBTQ+ people"],
      ["homoit0000016", "LGBTQ+ Afro-Canadians", "Afro-Canadian LGBTQ+ people"],
      ["homoit0000017", "LGBTQ+ Afro-Caribbeans", "Afro-Caribbean LGBTQ+ people"],
      ["homoit0000018", "LGBTQ+ Afro-Europeans", "Afro-European LGBTQ+ people"],
      ["homoit0000019", "LGBTQ+ Afro-Latin Americans", "Afro-Latin American LGBTQ+ people"],
      ["homoit0000073", "LGBTQ+ Asian-Americans", "Asian American LGBTQ+ people"],
      ["homoit0000074", "LGBTQ+ Asians", "Asian LGBTQ+ people"],
      ["homoit0000820", "LGBTQ+ biracial people", "Biracial LGBTQ+ people"],
      ["homoit0000208", "LGBTQ+ Black people", "Black LGBTQ+ people"],
      ["homoit0000860", "LGBTQ+ ethnic groups", "LGBTQ+ people in ethnic groups"],
      ["homoit0000886", "LGBTQ+ indigenous people", "Indigenous LGBTQ+ people"],
      ["homoit0000676", "LGBTQ+ Inuit", "Inuit LGBTQ+ people"],
      ["homoit0000253", "LGBTQ+ Latinx", "Latino/a/x LGBTQ+ people"],
      ["homoit0000903", "LGBTQ+ multi-racial people", "Multiracial LGBTQ+ people"],
      ["homoit0001037", "LGBTQ+ Native Americans", "Native American LGBTQ+ people"],
      ["homoit0001812", "LGBTQ+ Pacific Islander Americans", "Pacific Islander American LGBTQ+ people"],
      ["homoit0000913", "LGBTQ+ Papuans", "Papuan LGBTQ+ people"],
      ["homoit0000875", "LGBTQ+ Roma", "Romani LGBTQ+ people"],
      ["homoit0000243", "LGBTQ+ white people", "White LGBTQ+ people"],
      ["homoit0001151", "Queer African-Americans", "African American queer people"],
      ["homoit0001152", "Queer Afro-Canadians", "Afro-Canadian queer people"],
      ["homoit0001153", "Queer Afro-Caribbeans", "Afro-Caribbean queer people"],
      ["homoit0001154", "Queer Afro-Europeans", "Afro-European queer people"],
      ["homoit0001155", "Queer Afro-Latin Americans", "Afro-Latin American queer people"],
      ["homoit0001158", "Queer Asian Americans", "Asian American queer people"],
      ["homoit0001159", "Queer Asians", "Asian queer people"],
      ["homoit0001800", "Queer biracial people cchanged to", "Biracial queer people"],
      ["homoit0001163", "Queer Black people", "Black queer people"],
      ["homoit0001181", "Queer Latinx", "Latino/a/x queer people"],
      ["homoit0001805", "Queer multi-racial people", "Multiracial queer people"],
      ["homoit0001190", "Queer Native Americans", "Native American queer people"],
      ["homoit0001226", "Queer White people", "White queer people"],
      ["homoit0001384", "Transgender African-Americans", "African American transgender people"],
      ["homoit0001385", "Transgender Afro-Canadians", "Afro-Canadian transgender people"],
      ["homoit0001386", "Transgender Afro-Caribbeans", "Afro-Caribbean transgender people"],
      ["homoit0001387", "Transgender Afro-Europeans", "Afro-European transgender people"],
      ["homoit0001388", "Transgender Afro-Latin Americans", "Afro-Latin American transgender people"],
      ["homoit0001391", "Transgender Asian Americans", "Asian American transgender people"],
      ["homoit0001392", "Transgender Asians", "Asian transgender people"],
      ["homoit0001799", "Transgender biracial people", "Biracial transgender people"],
      ["homoit0001396", "Transgender Black people", "Black transgender people"],
      ["homoit0001417", "Transgender Latinx", "Latino/a/x transgender people"],
      ["homoit0001804", "Transgender multi-racial people", "Multiracial transgender people"],
      ["homoit0001426", "Transgender Native Americans", "Native American transgender people"],
      ["homoit0001461", "Transgender White people", "White transgender people"],
      ["homoit0000154", "Bisexual Jews", "Jewish bisexual people"],
      ["homoit0000497", "Gay Jews", "Jewish gay men"],
      ["homoit0000745", "Lesbian Jews", "Jewish lesbians"],
      ["homoit0000682", "LGBTQ+ Jews", "Jewish LGBTQ+ people"],
      ["homoit0000912", "LGBTQ+ Old Catholic Church", "LGBTQ+ Old Catholics"],
      ["homoit0000928", "LGBTQ+ religions", "LGBTQ+ religious people"],
      ["homoit0000948", "LGBTQ+ spirituality", "LGBTQ+ spiritual people"],
      ["homoit0001416", "Transgender Jews", "Jewish transgender people"],
      ["homoit0001180", "Queer Jews", "Jewish queer people"],
      ["homoit0000033", "ARC", "ARC (AIDS-Related Complex)"],
      ["homoit0000351", "DSM", "DSM (Diagnostic and Statistical Manual of Mental Disorders)"],
      ["homoit0001780", "T4T (Trans for Trans)", "t4t"],
      ["homoit0001788", "Beards", "Beards (Gay culture)"],
      ["homoit0000105", "Bears", "Bears (Gay culture)"],
      ["homoit0000219", "Bottoms", "Bottoms (Sex)"],
      ["homoit0000238", "Camp", "Camp (Gay culture)"],
      ["homoit0000267", "Chubs (Gay men)", "Chubs (Gay culture)"],
      ["homoit0001781", "Clocking (Transgender)", "Clocking (Gender)"],
      ["homoit0000284", "Clones (Gay men)", "Clones (Gay culture)"],
      ["homoit0000308", "Cottages", "Cottages (Gay culture)"],
      ["homoit0000309", "Cottaging", "Cottaging (Gay culture)"],
      ["homoit0000319", "Cruising", "Cruising (LGBTQ+ culture)"],
      ["homoit0000321", "Cubs", "Cubs (Gay culture)"],
      ["homoit0000366", "Drab", "Drab (LGBTQ+ culture)"],
      ["homoit0000598", "Goldilocks", "Goldilocks (Gay culture)"],
      ["homoit0000999", "LGBTQ+ masters", "LGBTQ+ masters (BDSM culture)"],
      ["homoit0001018", "LGBTQ+ mistresses", "LGBTQ+ mistresses (BDSM culture)"],
      ["homoit0001063", "Otters", "Otters (Gay culture)"],
      ["homoit0001065", "Outing", "Outing (LGBTQ+ culture)"],
      ["homoit0001145", "Pups", "Pups (Gay culture)"],
      ["homoit0001148", "Queens", "Queens (Gay culture)"],
      ["homoit0001233", "Reading (Transgender)", "Reading (Gender)"],
      ["homoit0000034", "Red ribbons", "Red ribbons (AIDS)"],
      ["homoit0000305", "Scat", "Scat (Sex)"],
      ["homoit0001318", "Slaves", "Slaves (BDSM culture)"],
      ["homoit0000288", "Stealth (Transgender)", "Stealth"],
      ["homoit0001353", "Switches", "Switches (Sex)"],
      ["homoit0001358", "Tearooms", "Tearooms (Gay culture)"],
      ["homoit0001376", "Tops", "Tops (Sex)"],
      ["homoit0001465", "Transitioning (Transgender)", "Transitioning (Gender)"],
      ["homoit0001476", "Tucking", "Tucking (Phallus)"],
      ["homoit0001479", "Twinks", "Twinks (Gay culture)"],
      ["homoit0000211", "Vampirism", "Vampirism (Sex)"],
      ["homoit0001779", "Vers", "Vers (Sex)"],
      ["homoit0001496", "Voice therapy (Transgender)", "Voice therapy (Gender)"],
      ["homoit0000597", "Water sports", "Water sports (Sex)"],
      ["homoit0001508", "Wolves", "Wolves (Gay culture)"],
      ["homoit0000596", "Goddess movement (Lesbians)", "Goddess movement"],
      ["homoit0000222", "Breasts", "Breast"],
      ["homoit0000232", "Buttocks", "Butt"],
      ["homoit0000389", "Femininity", "Femininities"],
      ["homoit0000563", "Gender binary", "Gender binaries"],
      ["homoit0000995", "Masculinity", "Masculinities"],
      ["homoit0001099", "Penises", "Penis"],
      ["homoit0001361", "Testes", "Testicle"],
      ["homoit0001488", "Vaginas", "Vagina"]
    ]
    say_with_time "Completed Term Pref. Label Changes V. 3.2" do 
      v_3_2_changes.each do |identifier, old_label, new_label|
        term = Term.find_by(identifier: identifier)
        old_er = EditRequest::where(term_id: term.id)[0] # points to term creation
        next if (old_er.version_release_id == 8) # Skip terms created this version
        old_pref_label = term.get_relationship_at_version_release(Relation::Pref_label, 8)[0]
        #p "#{old_label} --> (#{new_label}): #{old_pref_label}"

        new_lang = term.term_relationships.find_by(relation_id: Relation::Pref_label).language_id
        
        old_lang = old_pref_label[0]
        old_label = old_pref_label[1]

        changed_alt = old_er.my_changes[Relation::Alt_label].delete(["+", old_lang, old_label])
        old_er.my_changes[Relation::Alt_label].reject! {|c| (c[1] == old_lang and c[2].downcase == old_label.downcase)}
        
        old_er.save!

        #ol = (old_er.version_release_id == 6) ? Term.find_by(id: old_er.prev_term_id).pref_label : old_label
        
        new_er = EditRequest::makeEmptyER(term.id, change_time, 8, "Published", term.uri, term.identifier)
        prev_er = new_er.previous()
        the_changes = [
          [Relation::Pref_label, 0, ["-", old_lang, old_label]],
          [Relation::Pref_label, 1, ["+", new_lang, new_label]]
        ]
          
        #if term.term_relationships.where(relation_id: Relation::Alt_label).where("BINARY data = ?", old_label).count > 0
        if changed_alt
          the_changes << [Relation::Alt_label, 0, ["+", old_lang, old_label]]
        end
        CreateEditRequests::modify_edit_request(new_er, [], the_changes, [])
      end
    end
    v_3_2_redirects = ["homoit0000195", "homoit0000548", "homoit0000790", "homoit0001364", "homoit0001455",
                       "homoit0000774", "homoit0000916", "homoit0000917", "homoit0001507"]
    say_with_time "Completed Redirects V. 3.2" do 
      v_3_2_redirects.each do |identifier|
        term = Term.find_by(identifier: identifier)
        redirects_to = term.term_relationships.find_by(relation_id: Relation::Redirects_to).data
        new_er = EditRequest::makeEmptyER(term.id, change_time, 8, "Published", term.uri, term.identifier)
        CreateEditRequests::modify_edit_request(new_er, [], [[Relation::Redirects_to, 0, ["+", nil, redirects_to]]], [])
      end
    end
  end

  # Migrate a version release from the old version
  def self.migrate_version_release(version_release_id)
    v_str = VersionRelease.find_by(id: version_release_id).release_identifier
    terms = VersionReleaseTerm.where(version_release_id: version_release_id)
    terms_new = terms.where(change_type: "new")
    terms_updates = terms.where(change_type: "update")
    terms_redirects = terms.where(change_type: "redirect")
    say_with_time "Migrating Term Edits V. #{v_str} (#{terms.count} terms)" do
      terms_new.each do |vrt|
        EditRequest::makeFromTerm(vrt.term_id, version_release_id)
      end
      p "Completed Migration: V. #{v_str} New Terms (#{terms_new.count})"
      
      terms_updates.each do |vrt|
        term = Term.find_by(id: vrt.term_id)
        old_er = term.edit_requests[-1]
        prev_label = vrt.previous_label_language.split("@")

        new_label = old_er.my_changes[Relation::Pref_label][-1].clone
        new_label = term.term_relationships.where(relation_id: Relation::Pref_label)[0]
        new_label = ["+", new_label.language_id, new_label.data]
        
        unless term.edit_requests.count > 1 #already modded
          CreateEditRequests::modify_edit_request(old_er, [], [], [[Relation::Pref_label, []]])#["+", "en", prev_label[0]]]]])
        end
        new_er = EditRequest::makeEmptyER(term.id, vrt.created_at, version_release_id, "Published", term.uri, term.identifier)
        
        CreateEditRequests::modify_edit_request(new_er, [], [
                                                  [Relation::Pref_label, 0, ["-", prev_label[1], prev_label[0]]],
                                                  [Relation::Pref_label, 1, new_label]
                                                ], [])      
      end
      p "Completed Migration: V. #{v_str} Updated Terms (#{terms_updates.count})"
      
      terms_redirects.where(change_type: "redirect").each do |vrt|
        vrt.changed_uris.each do |uri|
          t = Term.find_by(uri: uri)
          er = EditRequest::makeEmptyER(t.id, vrt.created_at, version_release_id, "Published", vrt.term_uri, vrt.term_identifier)
          er.my_changes[Relation::Redirects_to] << ["+", nil, vrt.term_id.to_s]
          er.save!
        end
      end
      p "Completed Migration: V. #{v_str} Redirected Terms (#{terms_redirects.count})"
    end
  end

  # Move a value up to a certain version_release_id
  def self.bubble_up_change(parent, term, rel_id, value, version_release_id, created_at)
    term_hist = term.get_edit_requests().reverse()
    change = ["+", nil, value]
    term_hist.each do |er|
      if er.version_release_id >= version_release_id
        break
      end
      if er.my_changes[rel_id].delete(change)
        er.save!
        new_er = EditRequest.where(term_id: term.id).where(version_release_id: version_release_id)
        new_er = (new_er.count > 0) ? new_er[0] : EditRequest::makeEmptyER(term.id, created_at, version_release_id, "Published", term.uri, term.identifier)
        new_er.my_changes[rel_id] << change
        new_er.save!
        return true
      end
    end
    return false
  end
  # Move narrower/broader terms to proper location chronologically
  def self.sanitize_history()
    Term.all().each do |t|
      #p "Sanitizing #{t.pref_label} - #{t.id.to_s} - #{t.uri}"
      term_hist = t.get_edit_requests().reverse()
      term_hist.each do |er|
        er.my_changes[Relation::Broader].each do |broader_id|
          connected_term = Term.find_by(id: broader_id[2])
          CreateEditRequests::bubble_up_change(er.id, connected_term, Relation::Narrower, er.term_id.to_s, er.version_release_id, er.created_at)
        end
      end
    end
  end
  # Checks for duplicate fields in term history
  def self.sanity_check(term)
    term_history = term.get_edit_requests()
    error_count = 0
    Relation.all().each do |r|
      rel_hist = Set.new()
      term_history.reverse.each do |er|
        rel_changes = er.my_changes[r.id] 
        rel_changes.each do |rc|
          rel_change = CreateEditRequests::TRChange.new(rc[1], rc[2])
          if rc[0] == "+"
            if rel_hist.include?(rel_change)
              p "ERROR: ADDED PRE-EXISTING RELATIONSHIP"
              p " * #{er.version_release_id} -- #{er.term_id} -- #{r.name} -- #{rc[2]} -- #{er.my_changes['uri']}"
              error_count += 1
            else
              rel_hist.add(rel_change)
            end
          else
            if rel_hist.include?(rel_change)
              rel_hist.delete(rel_change)
            else
              p "ERROR: REMOVED NON-EXISTING RELATIONSHIP"
              p " * #{er.version_release_id} -- #{er.term_id} -- #{r.name} -- #{rc[2]} -- #{er.my_changes['uri']}"
              error_count += 1
            end
          end
        end
      end
    end
    return error_count
  end

  # Compares values produced by term history with those of term currently
  def self.sanity_check_intense(term)
    edit_requests = term.get_edit_requests().reverse()
    er_versions = edit_requests.map {|er| er.version_release_id}

    p "SANITY CHECK #{term.id} : #{term.pref_label} (#{term.uri})"
    p "Edited in versions: #{er_versions.to_s}"
    if er_versions.count == 0
      p "- SKIPPING"
      return 0
    end
    term_values = Hash.new
    er_values = Hash.new
    Relation.pluck(:id).each do |r|
      term_values[r] = Array.new
      er_values[r] = Array.new
    end
    term.term_relationships.each do |tr|
      term_values[tr.relation_id] << [tr.language_id, tr.data]
    end
    Relation.pluck(:id).each do |r|
      edit_requests.each do |er|
        rel_changes = er.my_changes[r]
        rel_changes.each do |rc|
          # p "#{term.pref_label} - [#{r}] (#{er.version_release_id}) -> #{rc}"
          # p er_values[r]
          rel_change = [rc[1], rc[2]]
          if rc[0] == "+"
            er_values[r] << rel_change
          else
            index = er_values[r].index(rel_change)
            unless index.nil?
              er_values[r].delete_at(index)
            end
          end
          #p er_values[r]
        end
      end
    end
    errors = 0
    output = []
    Relation.all().each do |r|
      next if r.id == Relation::Replaced_by
      a_minus_b = term_values[r.id] - er_values[r.id]
      b_minus_a = er_values[r.id] - term_values[r.id]
      if a_minus_b.count > 0 or b_minus_a.count > 0
        errors += a_minus_b.count + b_minus_a.count
        output << "-- #{r.name}"
        output << "--- EXPECTED: #{term_values[r.id].to_s}"
        output << "--- RECIEVED: #{er_values[r.id].to_s}"
        output << "--- MISSING:  #{a_minus_b}"
        output << "--- PHANTOMS: #{b_minus_a}"
      end
    end
    if errors > 0
      p "- ERRORS"
      output.each do |line|
        p line
      end
      p "================================================================"
      #pp edit_requests
    else
      p "- SUCCESS"
    end
    return errors
  end

  def self.sanity_check_all(intense = false)
    total_count = 0
    error_terms = 0
    Term.all().each do |t|
      errors = intense ? CreateEditRequests::sanity_check_intense(t) : CreateEditRequests::sanity_check(t) 
      if errors > 0
        error_terms += 1
        total_count += errors
      end
    end
    p "Sanity Check Completed: #{total_count} errors in #{error_terms} terms"
  end  
  
  def up
    # Handle expanding version_release table
    unless VersionRelease.count() > 3
      say_with_time "Expanding version_releases table" do
        add_column(:version_releases, :note, :text)
        VersionRelease.find_by(id: 1).update(id: 9,  :release_type => "Minor", :release_identifier => "3.3.0")
        VersionRelease.find_by(id: 2).update(id: 10, :release_type => "Minor", :release_identifier => "3.4.0")
        VersionRelease.find_by(id: 3).update(id: 11, :release_type => "Minor", :release_identifier => "3.5.0")
        VersionReleaseTerm.where(version_release_id: 1).update(version_release_id: 9)
        VersionReleaseTerm.where(version_release_id: 2).update(version_release_id: 10)
        VersionReleaseTerm.where(version_release_id: 3).update(version_release_id: 11)
        VersionRelease.create(:id => 1,
                              :release_identifier => "1.0.0",
                              :release_type => "Major",
                              :release_date => "2015",
                              :created_at => "2015-12-30 23:59:59",
                              :updated_at => "2015-12-30 23:59:59",
                              :vocabulary_identifier => "terms",
                              :vocabulary_id => 1)
        VersionRelease.create(:id => 2,
                              :release_identifier => "2.0.0",
                              :release_type => "Major",
                              :release_date => "May 2019",
                              :created_at => "2020-05-14 23:59:59",
                              :updated_at => "2020-05-14 23:59:59",
                              :vocabulary_identifier => "v2",
                              :vocabulary_id => 2)
        VersionRelease.create(:id => 3,
                              :release_identifier => "2.1.0",
                              :release_type => "Minor",
                              :release_date => "June 2020",
                              :created_at => "2020-06-04 23:59:59",
                              :updated_at => "2020-06-04 23:59:59",
                              :vocabulary_identifier => "v2",
                              :vocabulary_id => 2)
        VersionRelease.create(:id => 4,
                              :release_identifier => "2.2.0",
                              :release_type => "Minor",
                              :release_date => "June 2020",
                              :created_at => "2020-12-12 23:59:59",
                              :updated_at => "2020-12-12 23:59:59",
                              :vocabulary_identifier => "v2",
                              :vocabulary_id => 2)
        VersionRelease.create(:id => 5,
                              :release_identifier => "2.3.0",
                              :release_type => "Minor",
                              :release_date => "July 2021",
                              :created_at => "2021-07-02 23:59:59",
                              :updated_at => "2021-07-02 23:59:59",
                              :vocabulary_identifier => "v2",
                              :vocabulary_id => 2)
        VersionRelease.create(:id => 6,
                              :release_identifier => "3.0.0",
                              :release_type => "Major",
                              :release_date => "September 2021",
                              :created_at => "2021-09-02 23:59:59",
                              :updated_at => "2021-09-02 23:59:59",
                              :vocabulary_identifier => "v3",
                              :vocabulary_id => 3)
        VersionRelease.create(:id => 7,
                              :release_identifier => "3.1.0",
                              :release_type => "Minor",
                              :release_date => "December 2021",
                              :created_at => "2021-12-15 23:59:59",
                              :updated_at => "2021-12-15 23:59:59",
                              :vocabulary_identifier => "v3",
                              :vocabulary_id => 3)
        VersionRelease.create(:id => 8,
                              :release_identifier => "3.2.0",
                              :release_type => "Minor",
                              :release_date => "June 2022",
                              :created_at => "2022-06-15 23:59:59",
                              :updated_at => "2022-06-15 23:59:59",
                              :vocabulary_identifier => "v3",
                              :vocabulary_id => 3)
      end
    end
    unless ActiveRecord::Base.connection.table_exists?(:edit_requests)
      create_table :edit_requests do |t|
        t.references :term, null: false
        t.references :creator,   foreign_key: { to_table: :users }, type: :integer
        t.references :reviewer,  foreign_key: { to_table: :users }, type: :integer
        t.references :prev_term, foreign_key: { to_table: :terms }
        t.references :version_release,                              type: :integer
        t.references :parent,    foreign_key: { to_table: :edit_requests }, index: false
        t.string     :status
        t.datetime   :created_at, null: false
        t.datetime   :reviewed_at
        t.text       :my_changes
      end
      # Add term creations to edit_requests
      CreateEditRequests::migrate_term_creations(1, "1.0", 1, "1970-01-01", "2019-05-15")
      CreateEditRequests::migrate_term_creations(2, "2.0", 2, "1970-01-01", "2019-05-15")
      CreateEditRequests::migrate_term_creations(2, "2.1", 3, "2019-05-15", "2020-06-04")
      CreateEditRequests::migrate_term_creations(2, "2.2", 4, "2020-06-05", "2020-12-12")
      CreateEditRequests::migrate_term_creations(2, "2.3", 5, "2020-12-14", "2021-07-02")
      CreateEditRequests::sanitize_v_2_3_migration()
      
      #CreateEditRequests::migrate_term_creations(3, "3.0", 6, "1970-01-01", "2021-07-02")
      CreateEditRequests::migrate_term_creations_v_3_0()
      CreateEditRequests::migrate_term_creations(3, "3.1", 7, "2021-11-01", "2021-12-15")
      CreateEditRequests::sanitize_v_3_1_migration()

      CreateEditRequests::migrate_term_creations(3, "3.2", 8, "2022-01-01", "2022-06-16")
      CreateEditRequests::sanitize_v_3_2_migration()

      # V 3.3, 3.4, 3.5
      CreateEditRequests::migrate_version_release(9)
      CreateEditRequests::migrate_version_release(10)
      CreateEditRequests::migrate_version_release(11)

      CreateEditRequests::sanitize_history()
      
      CreateEditRequests::sanity_check_all(intense = true)

    end
  end
  def down
    if ActiveRecord::Base.connection.table_exists?(:edit_requests)
      drop_table :edit_requests
      say_with_time "Restoring Version Releases" do
        remove_column :version_releases, :note
        VersionRelease.where("id < 9").destroy_all()
        VersionRelease.find_by(id: 9 ).update(id: 1)
        VersionRelease.find_by(id: 10).update(id: 2)
        VersionRelease.find_by(id: 11).update(id: 3)
        VersionReleaseTerm.where(version_release_id: 9 ).update(version_release_id: 1)
        VersionReleaseTerm.where(version_release_id: 10).update(version_release_id: 2)
        VersionReleaseTerm.where(version_release_id: 11).update(version_release_id: 3)
      end
    end
  end
end
