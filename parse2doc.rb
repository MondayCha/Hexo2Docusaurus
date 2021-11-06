#!/usr/bin/ruby

require 'pathname'
require 'tmpdir'
require 'yaml'

def parse_markdown_file(filepath)
  output_directory_name = "./doc_output"
  text_all = File.read filepath.to_s

  # 分割博文的头部和正文
  begin_split = text_all.index('---')
  unless begin_split
    return
  end
  end_split = text_all.index('---', begin_split + 1)
  head = text_all[0, end_split]
  body = text_all[end_split, text_all.size]

  # 读取YAML头部信息
  temp_filename = File.join(Dir.tmpdir, "yaml_head.temp")
  temp_file = File.new(temp_filename, "w")
  temp_file.puts head
  temp_file.close
  hexo_yaml_info = YAML.load_file(temp_filename)
  File.delete(temp_filename)

  # 迁移所需的YAML信息
  # - Docusaurus文章属性: https://www.docusaurus.cn/docs/blog#header-options
  blog_name = hexo_yaml_info['title'].gsub(/[()『』《》]/, '('=>'「', ')'=>'」','『'=>'「', '』'=>'」','《'=>'「', '》'=>'」')
  create_time = hexo_yaml_info['date'].strftime("%Y-%m-%d %H:%M:%S")

  docusaurus_yaml_info = Hash.new
  docusaurus_yaml_info['title'] = blog_name
  
  # 将新头部和正文写入文件
  unless File.directory? output_directory_name
    Dir.mkdir(output_directory_name, 755)
  end

  categories = hexo_yaml_info['categories'] ? hexo_yaml_info['categories'] : '未分类'
  sub_path = File.join(output_directory_name, categories)
  unless File.directory? sub_path
    Dir.mkdir(sub_path, 755)
  end

  output_filename = File.join(sub_path, blog_name.gsub(' ','-') << ".md")
  if File.file? output_filename
    File.delete(output_filename)
  end
  output_file = File.open(output_filename, 'a+')
  output_file.puts docusaurus_yaml_info.to_yaml
  output_file.puts body
  output_file.puts "\n:::note\n" << "这是一篇从Hexo迁移的文章，创建于" << create_time << "\n:::"
  output_file.close
end


directory_name = "./"
file_list = Pathname.new(directory_name).children.select { |c| c.to_s.match('.*.md$') }
file_list.each do |filepath|
  puts filepath
  parse_markdown_file(filepath)
end