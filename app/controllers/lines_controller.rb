class LinesController < ApplicationController
  include AutoHtml

  before_action :get_line, only: [:edit, :update, :destroy]
  before_action :get_interviewee
  before_action :authenticate!, only: [:get_next_line]
  before_action :authenticate_interviewee!, except: [:get_next_line]

  def index
    @lines = @interviewee.lines
  end


  def create
    @scene = Scene.find(params[:scene_id])
    sequence = (@scene.lines.maximum(:sequence) || 0 ) + 1
    @line = Line.new(content: "대사를 입력해주세요.", line_type: "normal", sequence: sequence, interviewee: @scene.interviewee, scene: @scene)

    if @line.save
      flash[:success] = "대사가 성공적으로 추가되었습니다."
    else
      flash[:error] = "대사 추가에 실패하였습니다."
    end

    redirect_to interviewee_path(@scene.interviewee)
  end


  def show

  end

  def edit
  end

  def update

    @line = Line.find(params[:id])
    if @line.update(line_params)
      if @line.is_question?
        if @line.choices && @line.choices.count > 0
          #do nothing.
        else
          new_choice = Choice.create(content: "선택지", line_id: @line.id, sequence: 1, correct: true)
          new_choice.save         
        end

      end
      flash[:success] = "대사가 성공적으로 수정되었습니다."
    else
      flash[:error] = "대사 수정에 실패하였습니다."
    end
    redirect_to edit_scene_path(@line.scene)

  end


  def destroy

    @interviewee = @line.interviewee
    if @line.destroy
      flash[:success] = "대사가 성공적으로 삭제되었습니다."
    else
      flash[:error] = "대사 삭제에 실패하였습니다."
    end
    redirect_to edit_scene_path(@line.scene)

  end


  def get_next_line

    @scene = Scene.find(params[:scene_id])
    current_line = @scene.lines.find_by_sequence(params[:current_line])
    user_choice = current_line.choices.find_by_sequence(params[:user_choice])
    if(params[:answer_from_user] == "")
      UserAnswer.create(user: current_user, line: current_line, choice: user_choice, interviewee: @scene.interviewee)
    else
      UserAnswer.create(user: current_user, line: current_line, choice: user_choice, interviewee: @scene.interviewee, written_answer: params[:answer_from_user])
    end



    if current_line.next_line
      next_line = current_line.next_line
      next_line.content = make_auto_html(next_line.content, 480, 320)
      next_line.content = next_line.content + call_speed_wagon(next_line.link_name, next_line.link_content)
    end


    if current_line.line_type == "normal"

      render json: next_line.to_json({:include => :choices}), status: 200

    elsif current_line.line_type == "question"

      if user_choice.correct
        render json: next_line.to_json({:include => :choices}), status: 200

      else
        render json: {content: user_choice.response, sequence: current_line.sequence, choices: current_line.choices, line_type: 'question' }, status: 200
      end

    else
        render json: { error: "개발자에게 문의해주세요!" }, status: 403
    end

  end


private
  def make_auto_html(contents, width = 480, height = 320)
    return auto_html(contents){
      sized_image(:width =>width)
      youtube(:width => width, :height => height, :autoplay => false)
      link :target => "_blank", :rel => "nofollow"
      simple_format
    }
  end

  def call_speed_wagon(link_name, contents)
    if link_name == nil || contents == nil
      return ""
    end
    if link_name.strip.length == 0 || contents.strip.length == 0
      return ""
    end

    link_open  = " <a class=\"btn btn-primary\" role=\"button\" data-toggle=\"collapse\" href=\"#speedWagonContents\" aria-expanded=\"false\" aria-controls=\"speedWagonContents\">"
    link_close = "</a>"
    contents_open  = "<div class=\"collapse\" id=\"speedWagonContents\"><div class=\"well\">"
    contents_close = "</div></div>"
    return link_open + link_name + link_close + contents_open + make_auto_html(contents, 480, 320) + contents_close
  end

  def line_params
    params.require(:line).permit(:content, :line_type, :sequence, :scene, :link_name, :link_content)
  end
  def get_line
    @line = Line.find(params[:id])
  end


end
