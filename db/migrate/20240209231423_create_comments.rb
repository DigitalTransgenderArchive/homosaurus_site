class CreateComments < ActiveRecord::Migration[5.2]
  def self.create_test_data
    test_terms = ["homoit0000002"]
    test_edit_requests = [6065, 7652]
    test_terms.each do |t|
      Comment.create(content: "this is a test comment for the term", user_id: 2, commentable: Term.find_by(identifier: t), subject: "A new discussion about an issue")
    end
    sleep 1
    test_edit_requests.each do |er|
      Comment.create(content: "this is a test comment for the version change", user_id: 2, commentable: EditRequest.find_by(id: er), subject: "some new discussion about an issue")
    end
    sleep 1
    Comment.all().each do |c|
      Comment.create(content: "this is a test reply", user_id: 3, commentable: c)
    end
    sleep 1
    Comment.where(user_id: 3).each do |c|
      Comment.create(content: "this is a test of a nested reply", user_id: 4, commentable: c)
    end
    sleep 1
    Comment.where(user_id: [3, 4]).each do |c|
      Comment.create(content: "this is a further test of a nested reply", user_id: 5, commentable: c)
    end
  end
  def up
    unless ActiveRecord::Base.connection.table_exists?(:comments)
      create_table :comments do |t|
        t.text :content
        t.string :subject
        t.references :user, null: false
        t.references :commentable, polymorphic: true, null: false
        t.boolean :is_vote, default: false
        t.timestamps
      end
      CreateComments::create_test_data()
    end
  end
  def down
    drop_table :comments
  end
end
