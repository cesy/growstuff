class MembersController < ApplicationController
  load_and_authorize_resource

  skip_authorize_resource :only => :nearby

  after_action :expire_cache_fragments, :only => :create
  before_action :check_password, :only => :delete

  def index
    @sort = params[:sort]
    if @sort == 'recently_joined'
      @members = Member.confirmed.recently_joined.paginate(:page => params[:page])
    else
      @members = Member.confirmed.paginate(:page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.haml
      format.json { render :json => @members.to_json(:only => [:id, :login_name, :slug, :bio, :created_at, :location, :latitude, :longitude]) }
    end
  end

  def show
    @member       = Member.confirmed.find(params[:id])
    @twitter_auth = @member.auth('twitter')
    @flickr_auth  = @member.auth('flickr')
    @posts        = @member.posts
    # The garden form partial is called from the "New Garden" tab;
    # it requires a garden to be passed in @garden.
    # The new garden is not persisted unless Garden#save is called.
    @garden = Garden.new
    
    respond_to do |format|
      format.html # show.html.haml
      format.json { render :json => @member.to_json(:only => [:id, :login_name, :bio, :created_at, :slug, :location, :latitude, :longitude]) }
      format.rss { render(
        :layout => false,
        :locals => { :member => @member }
      )}
    end
  end

  def view_follows
    @member = Member.confirmed.find(params[:login_name])
    @follows = @member.followed.paginate(:page => params[:page])
  end

  def view_followers
    @member = Member.confirmed.find(params[:login_name])
    @followers = @member.followers.paginate(:page => params[:page])
  end
  
  def check_password
      validates :current_password, :presence => TRUE
  end
  
  def delete
    @member = Member.find(params[:id])
    
    # move any of their crops to cropbot
    if Role.crop_wranglers && (Role.crop_wranglers.include? @member)
      cropbot = Member.find_by_login_name('ex_wrangler')
      if Crop.find_by(creator: @member)
        # this is ugly, need to make it more efficient
        Crop.where(creator: @member).each do |crop|
          Crop.update(crop, creator: cropbot)
          crop.save!
        end
      end
    end
    
    # mark their comments as deleted
    ex_member = Member.find_by_login_name('ex_member')
    if Comment.find_by(author: @member)
      Comment.where(author: @member).each do |comment|
        Comment.update(comment, author: ex_member, body: "This comment was removed as the author deleted their account.")
        comment.save!
      end
    end
    
    # mark their posts as deleted
    ex_member = Member.find_by_login_name('ex_member')
    if Post.find_by(author: @member)
      Post.where(author: @member).each do |post|
        Post.update(post, author: ex_member, body: "This post was removed as the author deleted their account.")
        post.save!
      end
    end
    
    Member.update(@member, deleted?: true)
    if @member.save!
      redirect_to root_url, notice: "Member deleted."
    end
  end

  private

  def expire_cache_fragments
    expire_fragment("homepage_stats")
  end

end
