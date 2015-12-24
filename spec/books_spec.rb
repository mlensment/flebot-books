require 'flebot/books'

RSpec.describe Flebot::Books do
  it 'responds to execute' do
    books = Flebot::Books.new('felbot books', {'user1@test.ee' => '@user1'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq(books.help)
  end

  it 'shows balance' do
    books = Flebot::Books.new('felbot books balance', {'user1@test.ee' => '@user1'}, [{'user1@test.ee' => '@user1'}, {'user2@test.ee' => '@user2'}])
    response = books.execute
    expect(response).to eq('Congratulations, you have no debts between conversation members!')
  end

  it 'credits' do

  end
end
