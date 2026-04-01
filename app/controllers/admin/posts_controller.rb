module Admin
  class PostsController < BaseController
    before_action :set_post, only: %i[edit update destroy]

    def index
      @posts = Post.includes(:translations).order(created_at: :desc)
    end

    def new
      @post = Post.new
      @post.build_missing_translations
    end

    def create
      @post = Post.new(post_params)
      if @post.save
        redirect_to admin_posts_path, notice: "Post created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @post.build_missing_translations
    end

    def update
      if @post.update(post_params)
        if params[:translate].present?
          TranslatePostJob.perform_later(@post.id)
          redirect_to admin_posts_path, notice: "Post updated. Translation is running in the background."
        else
          redirect_to admin_posts_path, notice: "Post updated."
        end
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @post.destroy
      redirect_to admin_posts_path, notice: "Post deleted."
    end

    private

    def set_post
      @post = Post.find(params[:id])
    end

    def post_params
      params.require(:post).permit(
        :slug, :status, :published_at,
        translations_attributes: [
          :id, :locale, :title, :description, :body, :_destroy
        ]
      )
    end
  end
end
