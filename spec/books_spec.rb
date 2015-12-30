require 'spec_helper'
require 'flebot/books'

RSpec.describe Flebot::Books do
  before(:each) do
    @db = SQLite3::Database.new 'db/flebot-books.db'
    rows = @db.execute(
      "SELECT * FROM sqlite_master WHERE name = '#{Flebot::Books.table}' and type = 'table'"
    )

    @db.execute("DROP TABLE #{Flebot::Books.table};") if rows.any?
  end

  it 'responds to execute' do
    books = Flebot::Books.new('flebot books', {'user1@test.ee' => '@user1'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq(books.help)
  end

  it 'shows balance' do
    books = Flebot::Books.new('flebot books balance', {'user1@test.ee' => '@user1'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('Congratulations, there are no debts between conversation members!')
  end

  it 'does not credit with invalid arguments' do
    books = Flebot::Books.new('flebot books credit', {'user1@test.ee' => '@user1'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('ERROR: Too few arguments!')

    books = Flebot::Books.new('flebot books credit @user3', {'user1@test.ee' => '@user1'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('ERROR: Amount must be a number!')

    books = Flebot::Books.new('flebot books credit @user3 3.40', {'user1@test.ee' => '@user1'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('ERROR: There is no @user3 in this conversation!')
  end

  it 'does not credit for the user itself' do
    books = Flebot::Books.new('flebot books credit @user1 3.40', {'user1@test.ee' => '@user1'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('ERROR: Cannot credit yourself!')
  end

  it 'credits' do
    books = Flebot::Books.new('flebot books credit @user2 3.50', {'user1@test.ee' => '@user1'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('Credit action successful! @user2 owes @user1 3.50€')

    books = Flebot::Books.new('flebot books credit @user2 3.50', {'user1@test.ee' => '@user1'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('Credit action successful! @user2 owes @user1 7.00€')

    books = Flebot::Books.new('flebot books credit @user1 5', {'user2@test.ee' => '@user2'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('Credit action successful! @user2 owes @user1 2.00€')

    books = Flebot::Books.new('flebot books credit @user1 5', {'user2@test.ee' => '@user2'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('Credit action successful! @user1 owes @user2 3.00€')

    books = Flebot::Books.new('flebot books credit @user1 5', {'user3@test.ee' => '@user3'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}, {'user3@test.ee' => '@user3'}])
    response = books.execute
    expect(response).to eq('Credit action successful! @user1 owes @user3 5.00€')
  end

  it 'shows last transactions' do
    books = Flebot::Books.new('flebot books transactions', {'user1@test.ee' => '@user1'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('There are no transaction between conversation members.')

    books = Flebot::Books.new('flebot books credit @user1 5 star wars the other day', {'user2@test.ee' => '@user2'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('Credit action successful! @user1 owes @user2 5.00€')

    books = Flebot::Books.new('flebot books transactions', {'user1@test.ee' => '@user1'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('@user2 -> @user1 5.00€ - star wars the other day')

    # transaction between someone who is not in the other conversation
    books = Flebot::Books.new('flebot books credit @user1 5', {'user3@test.ee' => '@user3'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}, {'user3@test.ee' => '@user3'}])
    response = books.execute

    books = Flebot::Books.new('flebot books transactions', {'user1@test.ee' => '@user1'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('@user2 -> @user1 5.00€ - star wars the other day')

    books = Flebot::Books.new('flebot books transactions abc adfas asfa s', {'user1@test.ee' => '@user1'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('ERROR: Limit must be a number')
  end
end
