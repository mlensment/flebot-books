require 'sqlite3'
require 'bigdecimal'
require 'pry'

class Flebot
  class Books
    def initialize(msg_body, sender, members)
      @action = msg_body.split(' ')[2]
      @args = msg_body.split(' ', 4)[3]
      @sender = sender
      @members = members
      @member_emails = @members.reduce([]) {|list, member| list + member.keys }
      init_db
    end

    def help
      return "Books app keeps tabs on your cash flow between your friends\n"\
        "Avaliable actions are: [help, balance, credit, transactions]\n\n"\
        "help - shows this help message\n"\
        "balance - shows current balance between conversation members\n(example: flebot books balance)\n"\
        "transactions [@limit=10] - shows last transactions between conversation members\n(example: flebot books transactions 10)\n"\
        "credit @@fleep_handle_of_a_user @amount [@description] - initiates a credit transaction on @user's account\n"\
        "(example: flebot books credit @martin 3.50 star wars on 29.12.2015)"
    end

    def balance
      response = []
      @members.each do |x|
        x_email, x_handle = x.first[0], x.first[1]
        @members.each do |y|
          y_email, y_handle = y.first[0], y.first[1]

          debt = balance_between(x_email, y_email)
          if debt > 0
            response << "#{x_handle} owes #{y_handle} #{sprintf( "%.02f€", debt)}"
          end
        end
      end

      response << 'Congratulations, there are no debts between conversation members!' if response.empty?

      response.join("\n")
    end

    def credit
      return "ERROR: Too few arguments!" unless @args
      sender_email = @sender.first[0]
      sender_handle = @sender.first[1]
      subject_email = find_member_email_by_handle(@args.split(' ')[0])
      subject_handle = @args.split(' ')[0]
      amount = @args.split(' ')[1]
      description = @args.split(' ', 3)[2]

      return "ERROR: Amount must be a number!" unless is_number?(amount)
      return "ERROR: There is no #{subject_handle} in this conversation!" unless subject_email
      return "ERROR: Cannot credit yourself!" if sender_email == subject_email

      @db.execute(
        "INSERT INTO #{self.class.table} (debit_account, credit_account, amount, description, created_at)
          VALUES (?, ?, ?, ?, datetime())", [sender_email, subject_email, amount, description]
      )

      debt = balance_between(sender_email, subject_email)
      if debt > 0
        "Credit action successful! #{sender_handle} owes #{subject_handle} #{sprintf( "%.02f€", debt)}"
      else
        debt *= -1
        "Credit action successful! #{subject_handle} owes #{sender_handle} #{sprintf( "%.02f€", debt)}"
      end
    end

    def transactions
      emails = @member_emails.map {|x| "'#{x}'"}.join(', ')
      rows = @db.execute(
        "select * from #{self.class.table} where "\
        "debit_account IN (#{emails}) "\
        "AND credit_account IN (#{emails}) "\
        "order by created_at desc limit 10"
      )

      response = []
      rows.each do |x|
        debit_handle = find_member_handle_by_email(x[0])
        credit_handle = find_member_handle_by_email(x[1])
        response << "#{debit_handle} -> #{credit_handle} #{sprintf("%.02f€", x[2])} - #{x[3]}"
      end

      response << 'There are no transaction between conversation members.' if response.empty?
      response.join("\n")
    end

    def execute
      if ['help', 'balance', 'credit', 'transactions'].include?(@action)
        send(@action)
      else
        help
      end
    end

    def self.table
      ENV['FLEBOT_ENV'] == 'test' ? 'book_transactions_test' : 'book_transactions'
    end

    private
    def init_db
      @db = SQLite3::Database.new 'flebot-books.db'
      rows = @db.execute(
        "SELECT * FROM sqlite_master WHERE name = '#{self.class.table}' and type = 'table'"
      )

      return if rows.any?

      @db.execute("
        create table #{self.class.table} (
          debit_account varchar(100),
          credit_account varchar(100),
          amount numeric,
          description varchar(255),
          created_at datetime
        )"
      )
    end

    def balance_between(x_email, y_email)
      # member x debt to memeber y
      # money in (debt increases)
      credit = @db.execute(
        "SELECT SUM(amount) FROM #{self.class.table} where credit_account = ? and debit_account = ?", [x_email, y_email]
      ).flatten.first || 0.00

      # member y debt to memeber x
      # money out (debt decreases)
      debit = @db.execute(
        "SELECT SUM(amount) FROM #{self.class.table} where debit_account = ? and credit_account = ?", [x_email, y_email]
      ).flatten.first || 0.00

      BigDecimal(credit.to_s) - BigDecimal(debit.to_s)
    end

    def find_member_email_by_handle(handle)
      @members.each do |x|
        return x.key(handle) unless x.key(handle).nil?
      end
      nil
    end

    def find_member_handle_by_email(email)
      @members.each do |x|
        return x[email] unless x[email].nil?
      end
      nil
    end

    def is_number? string
      true if Float(string) rescue false
    end
  end
end
