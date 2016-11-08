# coding: utf-8
require 'rails_helper'

feature 'Polls' do

  context '#index' do

    scenario 'Polls can be listed' do
      polls = create_list(:poll, 3)

      visit polls_path

      polls.each do |poll|
        expect(page).to have_link(poll.name)
      end
    end

    scenario 'Filtering polls' do
      create(:poll, name: "Current poll")
      create(:poll, :incoming, name: "Incoming poll")
      create(:poll, :expired, name: "Expired poll")

      visit polls_path
      expect(page).to have_content('Current poll')
      expect(page).to_not have_content('Incoming poll')
      expect(page).to_not have_content('Expired poll')

      visit polls_path(filter: 'incoming')
      expect(page).to_not have_content('Current poll')
      expect(page).to have_content('Incoming poll')
      expect(page).to_not have_content('Expired poll')

      visit polls_path(filter: 'expired')
      expect(page).to_not have_content('Current poll')
      expect(page).to_not have_content('Incoming poll')
      expect(page).to have_content('Expired poll')
    end

    scenario "Current filter is properly highlighted" do
      visit polls_path
      expect(page).to_not have_link('Current')
      expect(page).to have_link('Incoming')
      expect(page).to have_link('Expired')

      visit polls_path(filter: 'incoming')
      expect(page).to have_link('Current')
      expect(page).to_not have_link('Incoming')
      expect(page).to have_link('Expired')

      visit polls_path(filter: 'expired')
      expect(page).to have_link('Current')
      expect(page).to have_link('Incoming')
      expect(page).to_not have_link('Expired')
    end
  end

  context 'Show' do
    let(:geozone) { create(:geozone) }
    let(:poll) { create(:poll) }

    scenario 'Lists questions from proposals as well as regular ones' do
      normal_question = create(:poll_question, poll: poll)
      proposal_question = create(:poll_question, poll: poll, proposal: create(:proposal))

      visit poll_path(poll)
      expect(page).to have_content(poll.name)

      expect(page).to have_content(normal_question.title)
      expect(page).to have_content(proposal_question.title)
    end

    scenario 'Non-logged in users' do
      create(:poll_question, poll: poll, valid_answers: 'Han Solo, Chewbacca')
      visit poll_path(poll)

      expect(page).to have_content('Han Solo')
      expect(page).to have_content('Chewbacca')
      expect(page).to have_content('You must Sign in or Sign up to participate')

      expect(page).to_not have_link('Han Solo')
      expect(page).to_not have_link('Chewbacca')
    end

    scenario 'Level 1 users' do
      create(:poll_question, poll: poll, geozone_ids: [geozone.id], valid_answers: 'Han Solo, Chewbacca')
      login_as(create(:user, geozone: geozone))
      visit poll_path(poll)

      expect(page).to have_content('You must verify your account in order to answer')

      expect(page).to have_content('Han Solo')
      expect(page).to have_content('Chewbacca')

      expect(page).to_not have_link('Han Solo')
      expect(page).to_not have_link('Chewbacca')
    end

    scenario 'Level 2 users in an incoming question' do
      incoming_poll = create(:poll, :incoming)
      create(:poll_question, poll: incoming_poll, geozone_ids: [geozone.id], valid_answers: 'Rey, Finn')
      login_as(create(:user, :level_two, geozone: geozone))

      visit poll_path(incoming_poll)

      expect(page).to have_content('Rey')
      expect(page).to have_content('Finn')
      expect(page).to_not have_link('Rey')
      expect(page).to_not have_link('Finn')

      expect(page).to have_content('This poll has not yet started')
    end

    scenario 'Level 2 users in an expired question' do
      expired_poll = create(:poll, :expired)
      create(:poll_question, poll: expired_poll, geozone_ids: [geozone.id], valid_answers: 'Luke, Leia')
      login_as(create(:user, :level_two, geozone: geozone))

      visit poll_path(expired_poll)

      expect(page).to have_content('Luke')
      expect(page).to have_content('Leia')
      expect(page).to_not have_link('Luke')
      expect(page).to_not have_link('Leia')

      expect(page).to have_content('This poll has finished')
    end

    scenario 'Level 2 users in a poll with questions for a geozone which is not theirs' do
      create(:poll_question, poll: poll, geozone_ids: [], valid_answers: 'Vader, Palpatine')
      login_as(create(:user, :level_two))

      visit poll_path(poll)

      expect(page).to have_content('The following questions are not available in your geozone')

      expect(page).to have_content('Vader')
      expect(page).to have_content('Palpatine')
      expect(page).to_not have_link('Vader')
      expect(page).to_not have_link('Palpatine')
    end

    scenario 'Level 2 users reading a same-geozone question' do
      create(:poll_question, poll: poll, geozone_ids: [geozone.id], valid_answers: 'Han Solo, Chewbacca')
      login_as(create(:user, :level_two, geozone: geozone))
      visit poll_path(poll)

      expect(page).to have_link('Han Solo')
      expect(page).to have_link('Chewbacca')
    end

    scenario 'Level 2 users reading a all-geozones question' do
      create(:poll_question, poll: poll, all_geozones: true, valid_answers: 'Han Solo, Chewbacca')
      login_as(create(:user, :level_two, geozone: geozone))
      visit poll_path(poll)
      save_and_open_page

      expect(page).to have_link('Han Solo')
      expect(page).to have_link('Chewbacca')
    end

    xscenario 'Level 2 users who have already answered' do
      question = create(:poll_question, poll: poll, geozone_ids:[geozone.id], valid_answers: 'Han Solo, Chewbacca')
      user = create(:user, :level_two, geozone: geozone)
      create(:question_answer, question: question, author: user, answer: 'Chewbacca')
      login_as user
      visit poll_path(poll)

      expect(page).to have_link('Han Solo')
      expect(page).to_not have_link('Chewbacca')
      expect(page).to have_content('Chewbacca')
    end

    xscenario 'Level 2 users answering', :js do
      create(:poll_question, poll: poll, geozone_ids: [geozone.id], valid_answers: 'Han Solo, Chewbacca')
      user = create(:user, :level_two, geozone: geozone)
      login_as user
      visit poll_path(poll)

      click_link 'Han Solo'

      expect(page).to_not have_link('Han Solo')
      expect(page).to have_link('Chewbacca')
    end

  end

end

