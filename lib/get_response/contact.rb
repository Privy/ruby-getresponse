module GetResponse

  # GetResponse contact
  class Contact
    attr_accessor :campaign, :name, :email, :cycle_day, :ip, :customs
    attr_reader :id


    def initialize(params)
      @campaign = params["campaign"]
      @name = params["name"]
      @email = params["email"]
      @cycle_day = params["cycle_day"]
      @ip = params["ip"]
      @customs = parse_customs(params["customs"])
      @id = params["id"]
    end


    # Add contact to the list. Method raises an exception <tt>GetResponseError</tt> if contact can't
    # be added (bad email syntax for example).
    # Example:
    #   GetResponse::Contact.create("email" => "john@doe.org", "name => "John D.", "campaign" => "N67")
    #
    # params:: Hash - attributes for new contact
    # returns:: Boolean - true if contact queued for create
    def self.create(params)
      contact = Contact.new(params)
      contact.save
    end


    # Find all contacts associated with GetResponse account
    #
    # returns:: [Contact]
    def self.find_all
      response = GetResponse::Connection.instance.send_request("get_contacts", {})

      response["result"].inject([]) do |contacts, resp|
        contacts << Contact.new(resp[1].merge("id" => resp[0]))
      end
    end


    # Save contact object. When object can't be saved than <tt>GetResponseError</tt> is raised,
    # otherwise returns <tt>true</tt>.
    #
    # returns:: Boolean
    def save
      connection = GetResponse::Connection.instance

      result = connection.send_request(:add_contact, self.attributes)
      if result["error"].nil?
        true
      else
        raise GetResponse::GetResponseError.new(result["error"])
      end
    end


    # Returns setted attributes as Hash.
    #
    # returns:: Hash
    def attributes
      attrs = {
        "campaign" => @campaign,
        "name" => @name,
        "email" => @email
      }

      attrs["ip"] = @ip if @ip
      attrs["cycle_day"] = @cycle_day if @cycle_day
      attrs["customs"] = @customs if @customs

      attrs
    end


    # Delete contact. If deleting contact was successfull method returns <tt>true</tt>. If contact
    # object hasn't <tt>id</tt> attribute <tt>GetResponseError</tt> exception is raised. Exception
    # is raised when try to delete already deleted contact.
    #
    # returns:: Boolean
    def destroy
      raise GetResponse::GetResponseError.new("Can't delete contact without id") unless @id

      resp = GetResponse::Connection.instance.send_request("delete_contact", { "contact" => @id })

      if resp["error"].nil?
        true
      else
        raise GetResponse::GetResponseError.new(resp["error"])
      end
    end


    # Update contact with passed attributes set. When object can't be saved than <tt>GetResponseError</tt>
    # is raised, otherwise returns <tt>true</tt>.
    #
    # net_attrs:: Hash
    def update(new_attrs)
      new_attrs.each_pair { |key, value| self.send(key + "=", value) }

      self.save
    end


    protected


    def parse_customs(customs)
      return unless customs
      customs.inject([]) do |customs_hash, custom|
        customs_hash << { "name" => custom[0], "content" => custom[1] }
      end
    end

  end

end

