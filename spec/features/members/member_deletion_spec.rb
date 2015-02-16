require 'rails_helper'

feature "member deletion" do

  context "with activity and followers" do
    let(:member) { FactoryGirl.create(:member) }
    let(:other_member) { FactoryGirl.create(:member) }
    let(:memberpost) { FactoryGirl.create(:post, :author => member) }
    let(:othermemberpost) { FactoryGirl.create(:post, :author => other_member) }
    let(:planting) { FactoryGirl.create(:planting, :owner => member) }
    let(:harvest) { FactoryGirl.create(:harvest, :owner => member) }
    let(:seed) { FactoryGirl.create(:seed, :owner => member) }
    let(:secondgarden) { FactoryGirl.create(:garden, :owner => member) }
    background do
      login_as(member)
      visit member_path(other_member)
      click_link 'Follow'
      logout
      login_as(other_member)
      visit member_path(member)
      click_link 'Follow'
      logout
      login_as(member)
      FactoryGirl.create(:comment, :author => member, :post => othermemberpost)
      FactoryGirl.create(:comment, :author => other_member, :post => memberpost)
      # deletion breaks if no wranglers exist
      FactoryGirl.create(:cropbot)
    end

    scenario "has option to delete on member profile page" do
      visit member_path(member)
      expect(page).to have_link "Delete account"
    end
    
    #scenario "requests confirmation for deletion", :js => true do
    #  visit member_path(member)
    #  Capybara.current_driver = :selenium
    #  click_link 'Delete account'
    #  expect(page.driver.browser.switch_to.alert.text).to eq("Are you sure?")
    #  Capybara.current_drive = :default
    #end

    scenario "deletes and removes bio" do
      visit member_path(member)
      click_link 'Delete account'
      expect(page).to have_content "Member deleted"
      visit member_path(member)
      # Once we get proper 404s, this will change to something friendlier
      # Currently it is the ActiveRecord error page
      expect(page).to have_content "NotFound"
    end
    
    context "deletes and" do
      background do
        member.delete
      end
    
      scenario "removes plantings, gardens, harvests and seeds" do
        visit garden_path(secondgarden)
        expect(page).not_to have_content "Garden"
        expect(page).to have_content "RuntimeError"
        visit planting_path(planting)
        expect(page).to have_content "NoMethodError"
        # uncomment this when we get proper 404s
        # expect(page).not_to have_content "#{planting.owner}"
        visit harvest_path(harvest)
        expect(page).to have_content "NoMethodError"
        # uncomment this when we get proper 404s
        #expect(page).not_to have_content "#{harvest.owner}"
        visit seed_path(seed)
        expect(page).to have_content "NoMethodError"
        # uncomment this when we get proper 404s
        #expect(page).not_to have_content "#{seed.owner}"
      end

      scenario "removes members from following" do
        visit member_follows_path(other_member)
        expect(page).not_to have_content "#{member.login_name}"
        visit member_followers_path(other_member)
        expect(page).not_to have_content "#{member.login_name}"
      end
    
      scenario "replaces posts with deletion note"
      
      scenario "leaves comments from other members on deleted post"
      
      scenario "replaces comments on others' posts with deletion note, leaving post intact"

    end
    
  end
  
  context "for a crop wrangler" do
    let(:member) { FactoryGirl.create(:crop_wrangling_member) }
    let(:otherwrangler) { FactoryGirl.create(:crop_wrangling_member) }
    let(:crop) { FactoryGirl.create(:crop, :creator => member) }
    FactoryGirl.create(:cropbot)
    let(:ex_wrangler) { FactoryGirl.create(:crop_wrangling_member, :login_name => "ex_wrangler") }
    
    scenario "leaves crops behind, reassigned to ex_wrangler" do
      login_as(otherwrangler)
      visit edit_crop_path(crop)
      expect(page).to have_content "#{member.login_name}"
      expect(page).not_to have_content "cropbot"
      expect(page).not_to have_content "ex_wrangler"
      member.delete
      visit edit_crop_path(crop)
      expect(page).not_to have_content "#{member.login_name}"
      expect(page).to have_content "ex_wrangler"
    end
    
  end
  
  context "for an admin" do
    let(:member) { FactoryGirl.create(:admin_member) }
    let(:crop) { FactoryGirl.create(:crop, :creator => member) }
    
    scenario "leaves crops behind, reassigned to cropbot"
    
    scenario "leaves forums behind, reassigned to ex_admin"
    
  end
  
end