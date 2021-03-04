require 'date'
require 'digest'

def get_teacher(id, client)
  f = "select first_name, middle_name, last_name, birthdate from teachers_seth where ID = #{id}"
  results = client.query(f).to_a
  if results.count.zero?
    puts "Teacher with ID #{id} was not found"
  else
    "Teacher #{results[0]['first_name']} #{results[0]['middle_name']} #{results[0]['last_name']} was born on #{(results[0]['birthdate']).strftime('%d %b %Y (%A)')}"
  end
end



def get_subject_teacher(id, client)
  q = "select s.name, t.first_name, t.middle_name, t.last_name FROM subjects_sethputz s JOIN teachers_seth t ON s.id = t.subject_id where t.subject_id = #{id};"
  result = client.query(q).to_a
  subject = ""
  name = ""
  if result.count.zero?
    puts "No matches found for id #{id}"
  else
    subject << "Subject: #{result[0]['name']}"
    result.map do |n|
      name << "Teacher: #{n['first_name']} #{n['middle_name']} #{n['last_name']}"
    end
  end
  name.gsub!("Teacher:", "\n Teacher:")
  return subject + name

end



def get_class_subjects(name, client)
  qry = "select c.class_name, t.first_name, t.middle_name, t.last_name, s.name
 FROM classes_sethputz c JOIN teachers_classes_sethputz tc ON tc.class_id = c.id_class
 JOIN teachers_seth t ON tc.teacher_id = t.id
 JOIN subjects_sethputz s ON s.id = t.subject_id WHERE c.class_name = '#{name}'"
  results = client.query(qry).to_a
  subjects_teachers = ""
  class_name = ""
  if results.count.zero?
    puts "#{name} has no subjects."
  else
    class_name << "Class: #{results[0]['class_name']}"
    results.each do |v|
      subjects_teachers << "Subjects: #{v['name']} (Teacher: #{v['first_name']} #{v['middle_name']} #{v['last_name']})"
      subjectsTeachers_edit = subjects_teachers.sub(/^.*(\(Teacher:)/, "").split
      subjectsTeachers_edit[0] = subjectsTeachers_edit[0][0] + "."
      subjectsTeachers_edit[1] = subjectsTeachers_edit[1][0] + "."
      subjectsTeachers_edit = subjectsTeachers_edit.join(" ")
      sub_teach_nm = subjects_teachers.sub(/^.*(\(Teacher:)/, "")
      subjects_teachers.gsub!("#{sub_teach_nm}", " #{subjectsTeachers_edit}")
    end
  end
  subjects_teachers.gsub!("Subjects:", "\n Subjects:")
  return class_name + subjects_teachers
end





def get_teacher_list_by_letter(letter, client)
  qry = "select t.first_name, t.middle_name, t.last_name, s.name FROM teachers_seth t
JOIN subjects_sethputz s ON t.subject_id = s.id WHERE t.first_name LIKE ('%#{letter}%') OR t.last_name LIKE ('%#{letter}%');"
  output = ""
  result = client.query(qry).to_a
  if result.count.zero?
    puts "No teachers include <#{letter}>"
  else
    result.each do |v|
      output << "teacher #{v['first_name'][0]}. #{v['middle_name'][0]}. #{v['last_name']} (Subject: #{v['name']}) \n"
    end
  end
  return output
end


def set_md5(client)
  md5 = Digest::MD5.new
  qry = "select CONCAT(first_name, ' ',middle_name, ' ', last_name, ', ', birthdate, ', ', subject_id, ', ', current_age) AS full_name, id FROM teachers_seth;"
  results = client.query(qry).to_a
  results.each do |v|
    md5 << "#{v['full_name']}"
    t = "update teachers_seth set md5 = '#{md5}' WHERE id = '#{v['id']}' ;"
    client.query(t)
    md5 = Digest::MD5.new
  end
end




def get_class_info(class_id, client)
  involved_teachers_qry = "select  t.first_name, t.middle_name, t.last_name
 FROM classes_sethputz c JOIN teachers_classes_sethputz tc ON tc.class_id = c.id_class
 JOIN teachers_seth t ON tc.teacher_id = t.id
 WHERE c.id_class = '#{class_id}'"
  qry = "select c.class_name, t.first_name, t.middle_name, t.last_name FROM teachers_seth t JOIN classes_sethputz c ON c.responsible_teacher_id = t.id WHERE id_class = #{class_id};"
  ivlv_tchr_qry = client.query(involved_teachers_qry).to_a
  cls = ""
  rspn = ""
  invlv = ""
  results = client.query(qry).to_a
  if results.empty?
    "Invalid class id or <#{class_id}> is higher then highest class id."
  else
    cls << "Class: #{results[0]['class_name']} \n Responsible Teacher: #{results[0]['first_name']} #{results[0]['middle_name']} #{results[0]['last_name']} \n"
    rspn << "Involved Teachers: \n"
    ivlv_tchr_qry.each do |l|
      invlv << "   #{l['first_name']} #{l['middle_name']} #{l['last_name']} \n"
    end
  end
  return cls + rspn + invlv
end



def get_teachers_by_year(year ,client)
  qry = "select first_name, middle_name, last_name from teachers_seth where year(birthdate) = #{year}"
  result = client.query(qry).to_a
  output = ""
  output_two = ""
  if result.empty?
    puts "Invalid birthdate or no teachers are from year #{year}."
  else
    output << "Teachers born in #{year}: \n"
    result.each do |v|
      output_two << "#{v['first_name']} #{v['middle_name']} #{v['last_name']} \n"
    end
  end
  return output + output_two
end




def time_rand (begin_date, end_date)
  rand(Date.parse(begin_date)..Date.parse(end_date))
end

def get_random_last_names(num, client)
  qry = "select last_name from last_names"
  @last_names = @last_names ? @last_names : client.query(qry).to_a
  @last_names.sample(num).map { |v| "#{v['last_name']}" }
end

def get_random_first_names (num, client)
  qry = "select FirstName AS name FROM male_names
          UNION
         select names as name from female_names"
  @first_names = @first_names ? @first_names : client.query(qry).to_a
  @first_names.sample(num).map { |v| "#{v['name']}" }
end





def random_names(n, client)
  if n <= 20000
    qry = "insert into random_people_seth (first_name, last_name, birthdate) VALUES"
    value_qry = ""
    n.times do
      first_name_sample = get_random_first_names(1, client)
      last_name_sample = get_random_last_names(1, client)
      time_sample = time_rand("1905-01-01", "2020-12-31")
      value_qry << "('#{first_name_sample[0]}', '#{last_name_sample[0]}', '#{time_sample}'),"
    end
    value_qry.chop! + ";"
    qry.concat(value_qry)
    client.query(qry)
  else
    random_names(20000, client)
    random_names(n - 20000, client)
  end
end

def word_count(string, substring)
  string.scan(/(?=#{substring})/).count
end

def clean(to_clean)
  clean = ""
  clean << to_clean
  clean.gsub!("Elem", " Elementary School")
  clean.gsub!("Elementary Schoolem", "Elementary School")
  clean.gsub!("K-12", "Public School")
  clean.gsub!("H S", "High School")
  clean.gsub!("HS", "High School")
  clean = "#{clean} District"
  clean.sub!("Schls", "Schools")
  if word_count(clean, "School" || "Schools") > 1
    if clean.include?("Schools") == true
      clean.sub!("Schools", "")
    else
      clean.sub!("School", "")
    end
    clean.gsub!("  ", " ")
  end
  clean.gsub!("School Schools", "School")
  clean.gsub!(" El ", " Elementary School ")
  clean.gsub!("Dist ", " ")
  clean.gsub!("  ", " ")
  return clean
end






def mt_dstrct_rprt_crd(client)
  begin
    table_creation = "create table montana_public_district_report_card_unique_dist_seth (id INT AUTO_INCREMENT PRIMARY KEY,name varchar(255), clean_name varchar(255), address varchar(255), city varchar(255), state varchar(255), zip varchar(255), UNIQUE (name, address, city, state, zip));"
    client.query(table_creation)
    qry = "select distinct school_name AS to_clean_name, address, city, state, zip FROM montana_public_district_report_card;"
    results = client.query(qry).to_a
    insrt_qry = "insert ignore into montana_public_district_report_card_unique_dist_seth (name, clean_name, address, city, state, zip) values "
    results.each do |element|
      cleaned = clean(element['to_clean_name'])
      insrt_qry << "('#{element['to_clean_name']}', '#{cleaned}', '#{element['address']}', '#{element['city']}', '#{element['state']}', '#{element['zip']}'),"
    end
    insrt_qry.chop! + ";"
    client.query(insrt_qry)
  rescue Mysql2::Error
    run_query = "insert ignore into montana_public_district_report_card_unique_dist_seth (name, address, city, state, zip) values "
    select_query = "select distinct school_name, address, city, state, zip FROM montana_public_district_report_card;"
    select_query_results = client.query(select_query).to_a
    select_query_results.each do |v|
      run_query << "('#{v['school_name']}', '#{v['address']}', '#{v['city']}', '#{v['state']}', '#{v['zip']}'),"
    end
    run_query.chop! + ";"
    client.query(run_query)
    find_null_values = "SELECT id, name, clean_name FROM montana_public_district_report_card_unique_dist_seth WHERE clean_name IS NULL;"
    find_null_values_results = client.query(find_null_values)
    find_null_values_results.each do |v|
      update_query = "update montana_public_district_report_card_unique_dist_seth SET clean_name = '#{clean(v['name'])}' WHERE id = #{v['id']};"
      client.query(update_query)
    end
  end
end



def cleaner(string_input)
  str = string_input.dup
  str = str.delete(".")
  str.gsub!("//", "/")
  if str.count("Hwy") > 1
    str.sub!("Hwy", "Highway")
    str.gsub!("Hwy", "")
  elsif str.count("Hwy") == 1
    str.gsub!("Hwy", "Highway")
  end
  if str.count("hwy") > 1
    str.sub!("hwy", "Highway")
    str.gsub!("hwy", "")
  else
    str.gsub!("hwy", "Highway")
  end
  if str.count("twp") > 1
    str.sub!(/.*\Ktwp/, "Township")
    str.gsub!("twp", "")
  else
    str.sub!("twp", "Township")
  end
  if str.count("Twp") > 1
    str.sub!(/.*\KTwp/, "Township")
    str.gsub!("Twp", "")
  else
    str.sub!("Twp", "Township")
  end
  if str.include?("/") == false && str.include?("(") == false
    str = str.downcase
  end
  if str.count("/") >= 2
    str = str.split("/")
    str[0], str[2] = str[2], str[0]
    str = str.join(" ")
  elsif str.count("/") == 1
    str = str.split("/")
    str[0], str[1] = str[1], str[0].downcase
    str = str.join(" ")
  end
  if str[-1] == ","
    str.chop!
  end
  if str.include?(",")
    str = str.split(",")
    str[1] = str[1].strip
    str[1] = " (#{str[1]})"
    str = str.join("")
  end
  str.gsub!("County County", "County")
  str.gsub!("County county", "County")
  str.gsub!("'", "")
  if str.include?("(")
  str = str.split("(")
  str[1] = str[1].split.map! {|m| m.capitalize!}.join(" ")
  str = str.join("(")
  end
  if str.include?("Co "); str.gsub!("County", ""); str.gsub!("Co ", "County"); end
  str.gsub!("Mt", "Mount")
  str.gsub!("Township township", "township")
  str.gsub!("Hgts", "Hights")
  str.gsub!("Ft", "Fort")
  str.gsub!("  ", " ")
  return str
end
def clean_office_names(client)
  qry = "select * from hle_dev_test_seth_putz;"
  run_qry = client.query(qry).to_a
  num = 0
  until num == run_qry.size
    update_query = "update hle_dev_test_seth_putz SET clean_name = '#{cleaner(run_qry[num]['candidate_office_name'])}', sentence = 'The candidate is running for the #{cleaner(run_qry[num]['candidate_office_name'])} office.' WHERE id = '#{run_qry[num]['id']}';"
    client.query(update_query)
    num += 1
  end
end