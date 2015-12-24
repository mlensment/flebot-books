class Flebot
  class Books
    def initialize(msg_body, sender, members)
      @action = msg_body.split(' ')[2]
      @subject = msg_body.split(' ')[3]
      @amount = msg_body.split(' ')[4]
      @sender = sender
      @memebers = members
    end

    def help
      return "Books app keeps tabs on your cash flow between your friends\n"\
        "Avaliable actions are: [balance, credit, debit]"
    end

    def balance
      return 'showing balance' + @memebers.join(',')
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
  end
end
