class CreateEditRequests < ActiveRecord::Migration[5.2]
  # additions is in the form [[field1, pos1, newval1],...]
  # removals is in the form [[field1, pos1],...]
  def self.modify_edit_request(er, removals, additions, changes)
    #er = EditRequest.find_by()
    p "MODIFYING ER"
    pp er
    removals.each do |r|
      er.my_changes[r[0]].delete_at(r[1])
    end
    additions.each do |a|
      er.my_changes[a[0]].insert(a[1], a[2])
    end    
    changes.each do |c|
      er.my_changes[c[0]] = c[1]
    end
    pp er
    er.save!
  end

  # given edit request, modify it to use the correct label. Create and return an edit request.
  def self.change_original_pref_label(er, change_time, correct_label, version_release_id)
    p er.my_changes[2]
    old_label = er.my_changes[2][0][2]

    er.my_changes[2][0][2] = correct_label
    er.save!
    p er.my_changes[2]
    new_er =  EditRequest::makeEmptyER(er.term_id, change_time, version_release_id, "Published", er.my_changes.uri, er.my_changes.identifier)
    
    new_er.my_changes[2].insert(0, ["-", "en", correct_label])
    new_er.my_changes[2].insert(0, ["+", "en", old_label])
    new_er.save!
    p new_er.my_changes[2]
    return new_er
  end


  # Seperates redirection from term history
  def self.postdate_redirect(er, change_time, new_vid)
    redirect_to = er.my_changes[12][0][2]
    er.my_changes[12] = []
    er.my_changes["visibility"] = "published"
    er.save!
    new_er = EditRequest::makeEmptyER(er.term_id, change_time, new_vid, vis = "Published", uri = er.my_changes["uri"], identifier = er.my_changes["identifier"])
    new_er.my_changes[12] = [["+", nil, redirect_to]]
    new_er.my_changes["visibility"] = "redirect"
    new_er.save!
    return new_er
    
  end
  def self.migrate_term_creations(vocab_id, version_string, version_id, start_date, end_date)
    terms = Term.where('vocabulary_id = ' + vocab_id.to_s + \
                       ' AND DATE_FORMAT(created_at, "%Y-%m-%d") > "' + start_date + '"' + \
                       ' AND DATE_FORMAT(created_at, "%Y-%m-%d") < "' + end_date + '" ').order(:pref_label)
    say_with_time "Migrating Term Creations V. #{version_string} (#{terms.count()} terms)" do
      i = 1
      terms.each do |t|
        puts ("  - " +  ("%.4d" % "#{i}") + " - " + ("%.5d" % "#{t.id}") + ":  #{t.pref_label}")
        EditRequest.makeFromTerm(t.id, version_id) 
        i += 1
      end
      p "Completed Migration: Term Creations V. #{version_string} (#{terms.count()} terms)"
    end
  end

  def self.sanitize_v_2_3_migration()
    # Modify edit requests from 2.2 
    CreateEditRequests::modify_edit_request(Term.find_by(id: 2046).edit_requests[0],
                                            [ [2, 0] ],
                                            [ [2, 0, ["+", "en", "Assigned female"] ],
                                              [4, 1, ["+", "en", "Assigned female at birth"]] ],
                                            [ ["uri", "http://homosaurus.org/v2/assignedFemale"],
                                              ["identifier", "assignedFemale"] ])
    CreateEditRequests::modify_edit_request(Term.find_by(id: 2048).edit_requests[0],
                                            [ [2, 0] ],
                                            [ [2, 0, ["+", "en", "Assigned male"]],
                                              [4, 1, ["+", "en", "Assigned male at birth"]] ],
                                            [ ["uri", "http://homosaurus.org/v2/assignedMale"],
                                              ["identifier", "assignedMale"] ])
    CreateEditRequests::modify_edit_request(Term.find_by(id: 2291).edit_requests[0],
                                            [ [2, 0], [4, 0] ],
                                            [ [2, 0, ["+", "en", "Culturally-specific gender identities"]] ],
                                            [ ["uri", "http://homosaurus.org/v2/culturallySpecificGenderIdentities"],
                                              ["identifier", "assignedMale"]])

    # Add changes from 2.3
    time = Term.find_by(id: 3617).created_at
    #EditRequest.makeFromTerm(t.id, version_id)
    er = EditRequest::makeEmptyER(2046, time, 5)
    CreateEditRequests::modify_edit_request(er, [],
                                            [ [2, 0, ["-", "en", "Assigned female"]],
                                              [2, 0, ["+", "en", "Assigned female at birth"]],
                                              [4, 0, ["-", "en", "Assigned female at birth"]],
                                              [4, 0, ["+", "en", "Assigned female"]] ],
                                            [ ["uri", "http://homosaurus.org/v2/assignedFemaleAtBirth"],
                                              ["identifier", "assignedFemaleAtBirth"] ])
    er = EditRequest::makeEmptyER(2048, time, 5)
    CreateEditRequests::modify_edit_request(er, [],
                                            [ [2, 0, ["-", "en", "Assigned male"]],
                                              [2, 0, ["+", "en", "Assigned male at birth"]],
                                              [4, 0, ["-", "en", "Assigned male at birth"]],
                                              [4, 0, ["+", "en", "Assigned male"]] ],
                                            [ ["uri", "http://homosaurus.org/v2/assignedMaleAtBirth"],
                                              ["identifier", "assignedMaleAtBirth"] ])
    er = EditRequest::makeEmptyER(2291, time, 5)
    CreateEditRequests::modify_edit_request(er, [],
                                            [ [2, 0, ["-", "en", "Culturally-specific gender identities"]],
                                              [2, 0, ["+", "en", "Non-Euro-American gender and sexual identities"]],
                                              [4, 0, ["-", "en", "Non-Euro-American gender and sexual identities"]],
                                              [4, 0, ["+", "en", "Culturally-specific gender identities"]] ],
                                            [ ["uri", "http://homosaurus.org/v2/nonEuroAmericanGenderAndSexualIdentities"],
                                              ["identifier", "nonEuroAmericanGenderAndSexualIdentities"] ])
  end

  def self.sanitize_v_3_1_migration()
    # Nudes -> Nude art
    change_time = Term.find_by(id: 5475).created_at
    
    CreateEditRequests::modify_edit_request(Term.find_by(id: 4737).edit_requests[0], [], [], [[2, [["+", "en", "Nudes"]]]])
    er = EditRequest::makeEmptyER(4737, change_time, 7)
    CreateEditRequests::modify_edit_request(er, [], [
                                              [2, 0, ["-", "en", "Nudes"]],
                                              [2, 0, ["+", "en", "Nude art"]]], [])


    # (LGBTQ -> LGBTQ+) && ([Term] (LGBTQ) -> LGBTQ+ Term)

    v_3_1_changes = {
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
      "homoit0000830" => "LGBTQ+ centres",
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
      "homoit0000298" => "LGBTQ+ community centres",
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
      "homoit0000876" => "LGBTQ+ health care centres",
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
      "homoit0000660" => "LGBTQ+ information centres",
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
      "homoit0000558" => "LGBTQ+ neighbourhoods",
      "homoit0001041" => "LGBTQ+ newsletters",
      "homoit0001042" => "LGBTQ+ newspapers",
      "homoit0000909" => "LGBTQ+ night life",
      "homoit0000910" => "LGBTQ+ nonviolent resistance",
      "homoit0000911" => "LGBTQ+ obituaries",
      "homoit0000912" => "LGBTQ+ Old Catholic Church",
      "homoit0000393" => "LGBTQ+ older people",
      "homoit0000856" => "LGBTQ+ older people's organisations",
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
      "homoit0001101" => "LGBTQ+ people of colour",
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
      "homoit0000935" => "LGBTQ+ self-defence",
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
      "homoit0001363" => "LGBTQ+ theatre",
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
      "homoit0000964" => "LGBTQ+ youth centres",
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
    say_with_time "Completed Term Pref. Label Changes V. 2.3" do
      v_3_1_changes.each do |identifier, pref_label|
        #p "#{identifier}  --  #{pref_label}"
        er = Term.find_by(identifier: identifier).edit_requests[0]
        next unless (er and er.version_release_id == 6)  # skip 3.1 term creations
        current_label = er.my_changes[2][0][2]
        prev_term = Term.find_by(id: er.prev_term_id)
        CreateEditRequests::modify_edit_request(er, [[4, 0]], [], [[2, [["+", "en", prev_term.pref_label]]]])
        new_er = EditRequest::makeEmptyER(er.term_id, change_time, 7)
        CreateEditRequests::modify_edit_request(new_er, [], [], [[2, [["-", "en", prev_term.pref_label],
                                                                      ["+", "en", pref_label]]]])
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
      ["homoit0000201", "Bisexual white people", "White bisexual people"],
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
      ["homoit0000555", "Gay white people", "White gay men"],
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
      ["homoit0000797", "Lesbian white people", "White lesbians"],
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
      ["homoit0000886", "LGBTQ+ Indigenous people", "Indigenous LGBTQ+ people"],
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
      ["homoit0001226", "Queer white people", "White queer people"],
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
      ["homoit0001461", "Transgender white people", "White transgender people"],
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
        old_er = EditRequest::where(term_id: term.id)[0]
        p "Pref label change: #{term.id}  -  #{identifier} - #{old_label} - #{new_label}"
        
        CreateEditRequests::modify_edit_request(old_er, [], [], [[2, [["+", "en", old_label]]]])
        
        new_er = EditRequest::makeEmptyER(term.id, change_time, 8, "Published", term.uri, term.identifier)
        CreateEditRequests::modify_edit_request(new_er, [], [
                                                  [2, 0, ["-", "en", old_label]],
                                                  [2, 1, ["+", "en", new_label]],
                                                  [4, 0, ["+", "en", old_label]]
                                                ], [])
      end
    end
    v_3_2_redirects = ["homoit0000195", "homoit0000548", "homoit0000790", "homoit0001364", "homoit0001455",
                       "homoit0000774", "homoit0000916", "homoit0000917", "homoit0001507"]
    say_with_time "Completed Redirects V. 3.2" do 
      v_3_2_redirects.each do |identifier|
        term = Term.find_by(identifier: identifier)
        CreateEditRequests::postdate_redirect(term.edit_requests[0], change_time, 8)
      end
    end
  end

  #def self.sanitize_v_3_3_migration()
  def self.sanitize_version_release_terms_migration(version_release_id)
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
      
      terms_new.where(change_type: "update").each do |vrt|
        term = Term.find_by(id: vrt.term_id)
        old_er = term.edit_requests[-1]
        unless term.edit_requests.count > 1 #already modded
          CreateEditRequests::modify_edit_request(old_er, [], [], [[2, ["+", "en", vrt.previous_label]]])
          #else
        end
        new_er = EditRequest::makeEmptyER(term.id, vrt.created_at, version_release_id, "Published", term.uri, term.identifier)
        CreateEditRequests::modify_edit_request(new_er, [], [
                                                  [2, 0, ["-", "en", vrt.previous_label]],
                                                  [2, 1, ["+", "en", term.pref_label]]
                                                ], [])      
      end
      p "Completed Migration: V. #{v_str} Updated Terms (#{terms_updates.count})"
      
      terms_updates.where(change_type: "redirect").each do |vrt|
        vrt.changed_uris.each do |uri|
          term = Term.
                   CreateEditRequests::postdate_redirect(Term.find_by(uri: uri).edit_requests[0], change_time, version_release_id)
        end
      end
      p "Completed Migration: V. #{v_str} Redirected Terms (#{terms_redirects.count})"
    end
  end
  def up
    # Handle expanding version_release table
    unless VersionRelease.count() > 2
      say_with_time "Expanding version_releases table" do 
        VersionRelease.find_by(id: 1).update(id: 9,  :release_type => "Minor")
        VersionRelease.find_by(id: 2).update(id: 10, :release_type => "Minor")
        VersionReleaseTerm.where(version_release_id: 1).update(version_release_id: 9)
        VersionReleaseTerm.where(version_release_id: 2).update(version_release_id: 10)
        VersionRelease.create(:id => 1,
                              :release_identifier => "1.0",
                              :release_type => "Major",
                              :release_date => "2015",
                              :created_at => "2015-12-30 23:59:59",
                              :updated_at => "2015-12-30 23:59:59",
                              :vocabulary_identifier => "terms",
                              :vocabulary_id => 1)
        VersionRelease.create(:id => 2,
                              :release_identifier => "2.0",
                              :release_type => "Major",
                              :release_date => "May 2019",
                              :created_at => "2020-05-14 23:59:59",
                              :updated_at => "2020-05-14 23:59:59",
                              :vocabulary_identifier => "v2",
                              :vocabulary_id => 2)
        VersionRelease.create(:id => 3,
                              :release_identifier => "2.1",
                              :release_type => "Minor",
                              :release_date => "June 2020",
                              :created_at => "2020-06-04 23:59:59",
                              :updated_at => "2020-06-04 23:59:59",
                              :vocabulary_identifier => "v2",
                              :vocabulary_id => 2)
        VersionRelease.create(:id => 4,
                              :release_identifier => "2.2",
                              :release_type => "Minor",
                              :release_date => "June 2020",
                              :created_at => "2020-12-12 23:59:59",
                              :updated_at => "2020-12-12 23:59:59",
                              :vocabulary_identifier => "v2",
                              :vocabulary_id => 2)
        VersionRelease.create(:id => 5,
                              :release_identifier => "2.3",
                              :release_type => "Minor",
                              :release_date => "July 2021",
                              :created_at => "2021-07-02 23:59:59",
                              :updated_at => "2021-07-02 23:59:59",
                              :vocabulary_identifier => "v2",
                              :vocabulary_id => 2)
        VersionRelease.create(:id => 6,
                              :release_identifier => "3.0",
                              :release_type => "Major",
                              :release_date => "September 2021",
                              :created_at => "2021-09-02 23:59:59",
                              :updated_at => "2021-09-02 23:59:59",
                              :vocabulary_identifier => "v3",
                              :vocabulary_id => 3)
        VersionRelease.create(:id => 7,
                              :release_identifier => "3.1",
                              :release_type => "Minor",
                              :release_date => "December 2021",
                              :created_at => "2021-12-15 23:59:59",
                              :updated_at => "2021-12-15 23:59:59",
                              :vocabulary_identifier => "v3",
                              :vocabulary_id => 3)
        VersionRelease.create(:id => 8,
                              :release_identifier => "3.2",
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
        t.string     :status
        t.datetime   :created_at, null: false
        t.datetime   :reviewed_at
        t.text       :my_changes
      end
      #migrate_term_creations(vocab_id, version_string, version_id, start_date, end_date)

      # Add term creations to edit_requests
      CreateEditRequests::migrate_term_creations(2, "2.0", 2, "1970-01-01", "2020-06-04")
      CreateEditRequests::migrate_term_creations(2, "2.1", 3, "2019-05-15", "2020-06-04")
      CreateEditRequests::migrate_term_creations(2, "2.2", 4, "2020-06-05", "2020-12-12")
      CreateEditRequests::migrate_term_creations(2, "2.3", 5, "2020-12-14", "2021-07-02")
      CreateEditRequests::sanitize_v_2_3_migration()
      
      CreateEditRequests::migrate_term_creations(3, "3.0", 6, "1970-01-01", "2021-07-02")
      CreateEditRequests::migrate_term_creations(3, "3.1", 7, "2021-11-01", "2021-12-15")
      CreateEditRequests::sanitize_v_3_1_migration()

      CreateEditRequests::migrate_term_creations(3, "3.2", 8, "2022-01-01", "2022-06-15")
      CreateEditRequests::sanitize_v_3_2_migration()

      # CreateEditRequests::migrate_term_creations(3, "3.3", 9, "2022-06-17", "2022-12-15")
      # CreateEditRequests::sanitize_v_3_3_migration()
      # V 3.3, 3.4
      CreateEditRequests::sanitize_version_release_terms_migration(9)
      CreateEditRequests::sanitize_version_release_terms_migration(10)

      #CreateEditRequests::migrate_term_creations(3, "3.3", 7, "2022-01-01", "2022-06-15")
      
      #CreateEditRequests::migrate_term_creations(3, "3.1", 6, "1970-01-01", "2020-07-02")
      #def self.migrate_term_creations(vocab_id, version_string, version_id, start_date, end_date)
    end
  end
  def down
    if ActiveRecord::Base.connection.table_exists?(:edit_requests)
      drop_table :edit_requests
      say_with_time "Restoring Version Releases" do
        VersionRelease.where("id < 9").destroy_all()
        VersionRelease.find_by(id: 9 ).update(id: 1)
        VersionRelease.find_by(id: 10).update(id: 2)
        VersionReleaseTerm.where(version_release_id: 9 ).update(version_release_id: 1)
        VersionReleaseTerm.where(version_release_id: 10).update(version_release_id: 2)
      end
    end
  end
end