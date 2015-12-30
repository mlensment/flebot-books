require 'spec_helper'
require 'flebot/books'

RSpec.describe Flebot::Books do
  before(:each) do
    @db = SQLite3::Database.new 'flebot-books.db'
    rows = @db.execute(
      "SELECT * FROM sqlite_master WHERE name = '#{Flebot::Books.table}' and type = 'table'"
    )
    
    @db.execute("DROP TABLE #{Flebot::Books.table};") if rows.any?
  end

  it 'responds to execute' do
    books = Flebot::Books.new('felbot books', {'user1@test.ee' => '@user1'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq(books.help)
  end

  it 'shows balance' do
    books = Flebot::Books.new('felbot books balance', {'user1@test.ee' => '@user1'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('Congratulations, there are no debts between conversation members!')
  end

  it 'does not credit with invalid arguments' do
    books = Flebot::Books.new('felbot books credit', {'user1@test.ee' => '@user1'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('ERROR: Amount  must be a number!')

    books = Flebot::Books.new('felbot books credit @user3', {'user1@test.ee' => '@user1'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('ERROR: Amount  must be a number!')

    books = Flebot::Books.new('felbot books credit @user3 3.40', {'user1@test.ee' => '@user1'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('ERROR: There is no @user3 in this conversation!')
  end

  it 'does not credit for the user itself' do
    books = Flebot::Books.new('felbot books credit @user1 3.40', {'user1@test.ee' => '@user1'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('ERROR: Cannot credit yourself!')
  end

  it 'credits' do
    books = Flebot::Books.new('felbot books credit @user2 3.50', {'user1@test.ee' => '@user1'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('Credit action successful! @user2 owes @user1 3.50€')

    books = Flebot::Books.new('felbot books credit @user2 3.50', {'user1@test.ee' => '@user1'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('Credit action successful! @user2 owes @user1 7.00€')

    books = Flebot::Books.new('felbot books credit @user1 5', {'user2@test.ee' => '@user2'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('Credit action successful! @user2 owes @user1 2.00€')

    books = Flebot::Books.new('felbot books credit @user1 5', {'user2@test.ee' => '@user2'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('Credit action successful! @user1 owes @user2 3.00€')

    books = Flebot::Books.new('felbot books credit @user1 5', {'user3@test.ee' => '@user3'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}, {'user3@test.ee' => '@user3'}])
    response = books.execute
    expect(response).to eq('Credit action successful! @user1 owes @user3 5.00€')
  end

  it 'shows last transactions' do
    books = Flebot::Books.new('felbot books transactions', {'user1@test.ee' => '@user1'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('There are no transaction between conversation members.')
  end
end
