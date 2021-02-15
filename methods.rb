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
    begin_date = begin_date.split("-")
    end_date = end_date.split("-")
    bgn_year = begin_date[0].to_i
    end_year = end_date[0].to_i
    bgn_month = begin_date[1].to_i
    end_month = end_date[1].to_i
    bgn_day = begin_date[2].to_i
    end_day = end_date[2].to_i
    new_bgn_date = Date.new(bgn_year, bgn_month, bgn_day)
    new_end_date = Date.new(end_year, end_month, end_day)
    return rand(new_bgn_date...new_end_date)
  end



def get_random_last_names(num, client)
  qry = "select last_name as l_names from last_names ORDER BY RAND();"
  @results = @results ? @results : client.query(qry).to_a
  ary_of_names = []
  @results.each do |v|
    num.times do ary_of_names << "#{v['last_name']}" end
  end
  puts ary_of_names
end



def get_random_first_names (num, client)
    qry = "select FirstName AS names FROM male_names
UNION
select names as names from female_names;"
    @results = @results ? @results : client.query(qry).to_a

    end_ary = []
    ary_of_names = []

    @results.each do |v|
      num.times do ary_of_names << "#{v['names']}" end
    end

    ary_of_names.uniq!

    num.times do sample = ary_of_names.sample
      end_ary << sample
      ary_of_names.delete(sample)
     end

    if end_ary.size > num
    until end_ary == num
      end_ary.pop
    end
    end
    return end_ary
  end







def random_names(num, client)
  f_qry = "select FirstName as first_names FROM male_names
UNION
select names as first_names FROM female_names;"
  s_qry = "select last_name as l_names from last_names ORDER BY RAND();"

  @last_name_results = @last_name_results ? @last_name_results : client.query(s_qry).to_a
  @first_name_results = @first_name_results ? @first_name_results : client.query(f_qry).to_a

  value_insert = ""
  lst_names = []
  frst_names = []
  insert_qry = "insert into random_people_seth (first_name, last_name, birthdate) VALUES "


  @last_name_results.each do |v|
    num.times do lst_names << "#{v['l_names']}" end
  end

  @first_name_results.each do |l|
    frst_names << "#{l['first_names']}"
  end

  num.times do
    last_name_sample = lst_names.sample
    first_name_sample = frst_names.sample
    begin_date = "1905-01-01"
    end_date = "2020-12-31"
    begin_date = begin_date.split("-")
    end_date = end_date.split("-")
    bgn_year = begin_date[0].to_i
    end_year = end_date[0].to_i
    bgn_month = begin_date[1].to_i
    end_month = end_date[1].to_i
    bgn_day = begin_date[2].to_i
    end_day = end_date[2].to_i
    new_bgn_date = Date.new(bgn_year, bgn_month, bgn_day)
    new_end_date = Date.new(end_year, end_month, end_day)
    random_date = rand(new_bgn_date...new_end_date)
    value_insert << "('#{first_name_sample}', '#{last_name_sample}', '#{random_date}'),"
    lst_names.delete(last_name_sample)
    frst_names.delete(first_name_sample)
  end

  value_insert.chop!
  value_insert.concat(";")
  insert_qry.concat(value_insert)
  client.query(insert_qry)
end