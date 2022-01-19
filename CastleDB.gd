class_name CastleDB

static func read(db_path:String): # -> Dictionary
	var data_file = File.new()
	if data_file.open(db_path, File.READ) != OK:
		push_error("could not open: " + db_path)
		return null
	var data_text = data_file.get_as_text()
	data_file.close()
	var data_parse = JSON.parse(data_text)
	if data_parse.error != OK:
		push_error(data_parse.error)
		return null
	return data_parse.result
