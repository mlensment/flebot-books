require 'sqlite3'
require 'bigdecimal'
require 'pry'

class Flebot
  class Books
    def initialize(msg_body, sender, members)
      @action = msg_body.split(' ')[2]
      @subject = msg_body.split(' ')[3]
      @amount = msg_body.split(' ')[4]
      @description = msg_body.split(' ')[5]
      @sender = sender
      @members = members
      init_db
    end

    def help
      return "Books app keeps tabs on your cash flow between your friends\n"\
        "Avaliable actions are: [balance, credit, debit]"
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
      sender_email = @sender.first[0]
      sender_handle = @sender.first[1]
      subject_email = find_member_email_by_handle(@subject)
      subject_handle = @subject

      return "ERROR: Amount #{@amount} must be a number!" unless is_number?(@amount)
      return "ERROR: There is no #{subject_handle} in this conversation." unless subject_email

      @db.execute(
        "INSERT INTO #{self.class.table} (debit_account, credit_account, amount, description)
          VALUES (?, ?, ?, ?)", [sender_email, subject_email, @amount, @description]
      )

      debt = balance_between(sender_email, subject_email)
      if debt > 0
        "Credit action successful! #{sender_handle} owes #{subject_handle} #{sprintf( "%.02f€", debt)}"
      else
        debt *= -1
        "Credit action successful! #{subject_handle} owes #{sender_handle} #{sprintf( "%.02f€", debt)}"
      end
    end

    def execute
      if ['help', 'balance', 'credit'].include?(@action)
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
          description varchar(255)
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

    def is_number? string
      true if Float(string) rescue false
    end
  end
end
