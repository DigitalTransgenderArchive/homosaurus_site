class ReleaseController < ApplicationController

  def index

  end

  # archived static releases
  def release_notes_2_1
    render :template => "releases/archive/release_notes_2_1"
  end

  def release_notes_2_2
    render :template => "releases/archive/release_notes_2_2"
  end

  def release_notes_2_3
    render :template => "releases/archive/release_notes_2_3"
  end

  def release_notes_3_0
    render :template => "releases/archive/release_notes_3_0"
  end

  def release_notes_3_1
    render :template => "releases/archive/release_notes_3_1"
  end

  def release_notes_3_2
    render :template => "releases/archive/release_notes_3_2"
  end

end