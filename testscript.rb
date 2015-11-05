controller = ScriptsController.new
parsed_script = controller.parse_script(Script.last.script)
cal = controller.interpret_parsed_script(parsed_script)
cal.publish
controller.write_cal(cal)