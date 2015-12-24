require 'sqlite3'
require 'bigdecimal'
require 'pry'

class Flebot
  class Books
    def initialize(msg_body, sender, members)
      @action = msg_body.split(' ')[2]
      @subject = msg_body.split(' ')[3]
      @amount = msg_body.split(' ')[4]
      @sender = sender
      @memebers = members
      init_db
    end

    def help
      return "Books app keeps tabs on your cash flow between your friends\n"\
        "Avaliable actions are: [balance, credit, debit]"
    end

    def balance
      @members = [{'mlensment@gmail.com' => '@mlensment'}, {'rainersai@gmail.com' => '@rainersai'}, { 'mihkel@sokk.ee' => '@mihkelsokk' }]

      response = []
      @members.each do |x|
        x_email, x_handle = x.first[0], x.first[1]
        @members.each do |y|
          y_email, y_handle = y.first[0], y.first[1]
          # member x debt to memeber y
          # money in (debt increases)
          credit = @db.execute(
            "SELECT SUM(amount) FROM book_transactions where credit_account = ? and debit_account = ?", [x_email, y_email]
          ).flatten.first || 0.00

          # member y debt to memeber x
          # money out (debt decreases)
          debit = @db.execute(
            "SELECT SUM(amount) FROM book_transactions where debit_account = ? and credit_account = ?", [x_email, y_email]
          ).flatten.first || 0.00

          debt = BigDecimal(credit.to_s) - BigDecimal(debit.to_s)
          if debt > 0
            response << "#{x_handle} owes #{y_handle} #{sprintf( "%.02f€", debt)}"
          end
        end
      end

      response << 'Congratulations, you have no debts between conversation members!' if response.empty?

      response.join("\n")
    end

    def credit
      return 'crediting'
    end

    def debit
      return 'debiting'
    end

    def execute
      if ['help', 'balance', 'credit', 'debit'].include?(@action)
        send(@action)
      else
        help
      end
    end

    private
    def init_db
      @db = SQLite3::Database.new 'flebot-books.db'
      rows = @db.execute <<-SQL
        SELECT * FROM sqlite_master WHERE name = 'book_transactions' and type = 'table';
      SQL

      return if rows.any?

      @db.execute <<-SQL
        create table book_transactions (
          debit_account varchar(100),
          credit_account varchar(100),
          amount numeric,
          description varchar(255)
        );
      SQL
    end
  end
end
