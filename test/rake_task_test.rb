require "test_helper"
require "rake"

class RakeTaskTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def setup
    Rails.application.load_tasks
    @original_stdout = $stdout
    @output = StringIO.new
    $stdout = @output
  end

  def teardown
    $stdout = @original_stdout
    Rake::Task.clear
    Rails.application.load_tasks
  end

  def invoke_task(task_name)
    @output.rewind
    @output.truncate(0)
    Rake::Task[task_name].reenable
    Rake::Task[task_name].invoke
  end

  def strip_color_codes(string)
    string.gsub(/\e\[\d+(?:;\d+)*m/, "")
  end

  test "taggable_records task lists all taggable classes" do
    invoke_task("no_fly_list:taggable_records")
    output = strip_color_codes(@output.string)

    assert_includes output, "Car"
    assert_includes output, "Passenger"
    assert_includes output, "Truck"
    assert_match /Found \d+ taggable classes:/, output
  end

  test "tag_records task lists all tag classes" do
    invoke_task("no_fly_list:tag_records")
    output = strip_color_codes(@output.string)

    assert_includes output, "ApplicationTag"
    assert_includes output, "PassengerTag"
    assert_match /Found \d+ tag classes:/, output
  end

  test "check_taggable_records task validates table existence" do
    invoke_task("no_fly_list:check_taggable_records")
    output = strip_color_codes(@output.string)

    assert_match /Checking.*Car/, output
    assert_match /✓.*Table exists/, output
    assert_match /✓.*Required columns present/, output
    assert_match /✓.*All columns:/, output
  end

  test "check_taggable_records handles missing columns" do
    Car.connection.create_table :car_tags_temp, force: true do |t|
      t.timestamps
    end

    Car.connection.execute("INSERT INTO car_tags_temp (id, created_at, updated_at) SELECT id, created_at, updated_at FROM car_tags")
    Car.connection.drop_table :car_tags
    Car.connection.rename_table :car_tags_temp, :car_tags

    Car.reset_column_information
    CarTag.reset_column_information

    invoke_task("no_fly_list:check_taggable_records")
    output = strip_color_codes(@output.string)

    assert_match /!.*Missing required columns: name/, output

    # Restore table structure
    Car.connection.create_table :car_tags, force: true do |t|
      t.string :name
      t.timestamps
    end
    Car.reset_column_information
    CarTag.reset_column_information
  end
end
