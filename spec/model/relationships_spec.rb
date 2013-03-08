# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe Her::Model::Relationships do
  context "setting relationships without details" do
    before do
      spawn_model "Foo::User"
    end

    it "handles a single 'has_many' relationship" do
      Foo::User.has_many :comments
      Foo::User.relationships[:has_many].should == [{ :name => :comments, :class_name => "Comment", :path => "/comments", :inverse_of => nil }]
    end

    it "handles multiples 'has_many' relationship" do
      Foo::User.has_many :comments
      Foo::User.has_many :posts
      Foo::User.relationships[:has_many].should == [{ :name => :comments, :class_name => "Comment", :path => "/comments", :inverse_of => nil }, { :name => :posts, :class_name => "Post", :path => "/posts", :inverse_of => nil }]
    end

    it "handles a single 'has_one' relationship" do
      Foo::User.has_one :category
      Foo::User.relationships[:has_one].should == [{ :name => :category, :class_name => "Category", :path => "/category" }]
    end

    it "handles multiples 'has_one' relationship" do
      Foo::User.has_one :category
      Foo::User.has_one :role
      Foo::User.relationships[:has_one].should == [{ :name => :category, :class_name => "Category", :path => "/category" }, { :name => :role, :class_name => "Role", :path => "/role" }]
    end

    it "handles a single belongs_to relationship" do
      Foo::User.belongs_to :organization
      Foo::User.relationships[:belongs_to].should == [{ :name => :organization, :class_name => "Organization", :foreign_key => "organization_id", :path => "/organizations/:id" }]
    end

    it "handles multiples 'belongs_to' relationship" do
      Foo::User.belongs_to :organization
      Foo::User.belongs_to :family
      Foo::User.relationships[:belongs_to].should == [{ :name => :organization, :class_name => "Organization", :foreign_key => "organization_id", :path => "/organizations/:id" }, { :name => :family, :class_name => "Family", :foreign_key => "family_id", :path => "/families/:id" }]
    end
  end

  context "setting relationships with details" do
    before do
      spawn_model "Foo::User"
    end

    it "handles a single 'has_many' relationship" do
      Foo::User.has_many :comments, :class_name => "Post", :inverse_of => :admin
      Foo::User.relationships[:has_many].should == [{ :name => :comments, :class_name => "Post", :path => "/comments", :inverse_of => :admin }]
    end

    it "handles a single 'has_one' relationship" do
      Foo::User.has_one :category, :class_name => "Topic", :foreign_key => "topic_id"
      Foo::User.relationships[:has_one].should == [{ :name => :category, :class_name => "Topic", :foreign_key => "topic_id", :path => "/category" }]
    end

    it "handles a single belongs_to relationship" do
      Foo::User.belongs_to :organization, :class_name => "Business", :foreign_key => "org_id"
      Foo::User.relationships[:belongs_to].should == [{ :name => :organization, :class_name => "Business", :foreign_key => "org_id", :path => "/organizations/:id" }]
    end

    context "inheriting relationships from a superclass" do
      it "copies relationships to the subclass" do
        Foo::User.has_many :comments, :class_name => "Post"
        subclass = Class.new(Foo::User)
        subclass.relationships.object_id.should_not == Foo::User.relationships.object_id
        subclass.relationships[:has_many].length.should == 1
        subclass.relationships[:has_many].first[:class_name].should == "Post"
      end
    end
  end

  context "handling relationships without details" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke", :comments => [{ :id => 2, :body => "Tobias, you blow hard!", :user_id => 1 }, { :id => 3, :body => "I wouldn't mind kissing that man between the cheeks, so to speak", :user_id => 1 }], :role => { :id => 1, :body => "Admin" }, :organization => { :id => 1, :name => "Bluth Company" }, :organization_id => 1 }.to_json] }
          stub.get("/users/2") { |env| [200, {}, { :id => 2, :name => "Lindsay Fünke", :organization_id => 2 }.to_json] }
          stub.get("/users/1/comments") { |env| [200, {}, [{ :id => 4, :body => "They're having a FIRESALE?" }].to_json] }
          stub.get("/users/2/comments") { |env| [200, {}, [{ :id => 4, :body => "They're having a FIRESALE?" }, { :id => 5, :body => "Is this the tiny town from Footloose?" }].to_json] }
          stub.get("/users/2/role") { |env| [200, {}, { :id => 2, :body => "User" }.to_json] }
          stub.get("/users/1/role") { |env| [200, {}, { :id => 3, :body => "User" }.to_json] }
          stub.get("/users/1/posts") { |env| [200, {}, {:id => 1, :body => 'blogging stuff', :admin_id => 1 }.to_json] }
          stub.get("/organizations/1") { |env| [200, {}, { :id => 1, :name => "Bluth Company Foo" }.to_json] }
          stub.post("/users") { |env| [200, {}, { :id => 5, :name => "Mr. Krabs", :comments => [{ :id => 99, :body => "Rodríguez, nasibisibusi?", :user_id => 5 }], :role => { :id => 1, :body => "Admin" }, :organization => { :id => 3, :name => "Krusty Krab" }, :organization_id => 3 }.to_json] }
          stub.put("/users/5") { |env| [200, {}, { :id => 5, :name => "Clancy Brown", :comments => [{ :id => 99, :body => "Rodríguez, nasibisibusi?", :user_id => 5 }], :role => { :id => 1, :body => "Admin" }, :organization => { :id => 3, :name => "Krusty Krab" }, :organization_id => 3 }.to_json] }
          stub.delete("/users/5") { |env| [200, {}, { :id => 5, :name => "Clancy Brown", :comments => [{ :id => 99, :body => "Rodríguez, nasibisibusi?", :user_id => 5 }], :role => { :id => 1, :body => "Admin" }, :organization => { :id => 3, :name => "Krusty Krab" }, :organization_id => 3 }.to_json] }

          stub.get("/organizations/2") do |env|
            if env[:params]["admin"] == "true"
              [200, {}, { :id => 2, :name => "Bluth Company (admin)" }.to_json]
            else
              [200, {}, { :id => 2, :name => "Bluth Company" }.to_json]
            end
          end
        end
      end

      spawn_model "Foo::User" do
        has_many :comments
        has_one :role
        belongs_to :organization
        has_many :posts, :inverse_of => :admin
      end
      spawn_model "Foo::Comment" do
        belongs_to :user
      end
      spawn_model "Foo::Post" do
        belongs_to :admin, :class_name => 'Foo::User'
      end

      spawn_model "Foo::Organization"
      spawn_model "Foo::Role"

      @user_with_included_data = Foo::User.find(1)
      @user_without_included_data = Foo::User.find(2)
    end

    let(:user_with_included_data_after_create) { Foo::User.create }
    let(:user_with_included_data_after_save_existing) { Foo::User.save_existing(5, :name => "Clancy Brown") }
    let(:user_with_included_data_after_destroy) { Foo::User.new(:id => 5).destroy }

    it "maps an array of included data through has_many" do
      @user_with_included_data.comments.first.should be_a(Foo::Comment)
      @user_with_included_data.comments.length.should == 2
      @user_with_included_data.comments.first.id.should == 2
      @user_with_included_data.comments.first.body.should == "Tobias, you blow hard!"
    end

    it "does not refetch the parents models data if they have been fetched before" do
      @user_with_included_data.comments.first.user.object_id.should == @user_with_included_data.object_id
    end

    it "uses the given inverse_of key to set the parent model" do
      @user_with_included_data.posts.first.admin.object_id.should == @user_with_included_data.object_id
    end

    it "fetches data that was not included through has_many" do
      @user_without_included_data.comments.first.should be_a(Foo::Comment)
      @user_without_included_data.comments.length.should == 2
      @user_without_included_data.comments.first.id.should == 4
      @user_without_included_data.comments.first.body.should == "They're having a FIRESALE?"
    end

    it "fetches has_many data even if it was included, only if called with parameters" do
      @user_with_included_data.comments(:foo_id => 1).length.should == 1
    end

    it "maps an array of included data through has_one" do
      @user_with_included_data.role.should be_a(Foo::Role)
      @user_with_included_data.role.id.should == 1
      @user_with_included_data.role.body.should == "Admin"
    end

    it "fetches data that was not included through has_one" do
      @user_without_included_data.role.should be_a(Foo::Role)
      @user_without_included_data.role.id.should == 2
      @user_without_included_data.role.body.should == "User"
    end

    it "fetches has_one data even if it was included, only if called with parameters" do
      @user_with_included_data.role(:foo_id => 2).id.should == 3
    end

    it "maps an array of included data through belongs_to" do
      @user_with_included_data.organization.should be_a(Foo::Organization)
      @user_with_included_data.organization.id.should == 1
      @user_with_included_data.organization.name.should == "Bluth Company"
    end

    it "fetches data that was not included through belongs_to" do
      @user_without_included_data.organization.should be_a(Foo::Organization)
      @user_without_included_data.organization.id.should == 2
      @user_without_included_data.organization.name.should == "Bluth Company"
    end

    it "fetches belongs_to data even if it was included, only if called with parameters" do
      @user_with_included_data.organization(:foo_id => 1).name.should == "Bluth Company Foo"
    end

    it "can tell if it has a relationship" do
      @user_without_included_data.has_relationship?(:unknown_relationship).should be_false
      @user_without_included_data.has_relationship?(:organization).should be_true
    end

    it "fetches the resource corresponding to a named relationship" do
      @user_without_included_data.get_relationship(:unknown_relationship).should be_nil
      @user_without_included_data.get_relationship(:organization).name.should == "Bluth Company"
    end

    it "pass query string parameters when additional arguments are passed" do
      @user_without_included_data.organization(:admin => true).name.should == "Bluth Company (admin)"
    end

    [:create, :save_existing, :destroy].each do |type|
      context "after #{type}" do
        let(:subject) { self.send("user_with_included_data_after_#{type}")}

        it "maps an array of included data through has_many" do
          subject.comments.first.should be_a(Foo::Comment)
          subject.comments.length.should == 1
          subject.comments.first.id.should == 99
          subject.comments.first.body.should == "Rodríguez, nasibisibusi?"
        end

        it "maps an array of included data through has_one" do
          subject.role.should be_a(Foo::Role)
          subject.role.id.should == 1
          subject.role.body.should == "Admin"
        end
      end
    end
  end

  context "handling relationships with details" do
    before do
      Her::API.setup :url => "https://api.example.com" do |builder|
        builder.use Her::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke", :organization => { :id => 1, :name => "Bluth Company" }, :organization_id => 1 }.to_json] }
          stub.get("/users/2") { |env| [200, {}, { :id => 2, :name => "Lindsay Fünke", :organization_id => 1 }.to_json] }
          stub.get("/users/3") { |env| [200, {}, { :id => 2, :name => "Lindsay Fünke", :organization => nil }.to_json] }
          stub.get("/companies/1") { |env| [200, {}, { :id => 1, :name => "Bluth Company" }.to_json] }
        end
      end

      spawn_model "Foo::User" do
        belongs_to :company, :path => "/organizations/:id", :foreign_key => :organization_id
      end

      spawn_model "Foo::Company"

      @user_with_included_data = Foo::User.find(1)
      @user_without_included_data = Foo::User.find(2)
      @user_with_included_nil_data = Foo::User.find(3)
    end

    it "maps an array of included data through belongs_to" do
      @user_with_included_data.company.should be_a(Foo::Company)
      @user_with_included_data.company.id.should == 1
      @user_with_included_data.company.name.should == "Bluth Company"
    end

    it "does not map included data if it’s nil" do
      @user_with_included_nil_data.organization.should be_nil
    end

    it "fetches data that was not included through belongs_to" do
      @user_without_included_data.company.should be_a(Foo::Company)
      @user_without_included_data.company.id.should == 1
      @user_without_included_data.company.name.should == "Bluth Company"
    end
  end
end
