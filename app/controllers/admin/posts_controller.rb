module Admin
  class PostsController < BaseController
    before_action :set_post, only: %i[edit update destroy translate]

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
        redirect_to admin_posts_path, notice: "Post updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def translate
      locales = Array(params[:locales]).reject(&:blank?)
      if locales.empty?
        redirect_to edit_admin_post_path(@post), alert: "번역할 언어를 선택해주세요."
        return
      end
      locales.each { |locale| TranslatePostJob.perform_later(@post.id, locale) }
      redirect_to edit_admin_post_path(@post), notice: "#{locales.size}개 언어 번역이 백그라운드에서 시작됐습니다."
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
          :id, :locale, :title, :description, :body, :cta_text, :cta_url, :_destroy
        ]
      )
    end
  end
end
