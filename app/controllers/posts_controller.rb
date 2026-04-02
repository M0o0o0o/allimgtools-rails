class PostsController < ApplicationController
  BLOG_LOCALE = "en"

  def index
    @posts = Post.published
                 .with_locale(BLOG_LOCALE)
                 .includes(:translations)
                 .order(published_at: :desc)
                 .page(params[:page]).per(9)
  end

  def show
    @post = Post.published.find_by!(slug: params[:slug])
    @translation = @post.translation_for(BLOG_LOCALE)
    redirect_to posts_path unless @translation
  end
end
