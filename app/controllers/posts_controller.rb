class PostsController < ApplicationController
  def index
    @posts = Post.published
                 .with_locale(I18n.locale)
                 .includes(:translations)
                 .order(published_at: :desc)
                 .page(params[:page]).per(9)
  end

  def show
    @post = Post.published.find_by!(slug: params[:slug])
    @translation = @post.translation_for(I18n.locale)
    redirect_to posts_path unless @translation
  end
end
