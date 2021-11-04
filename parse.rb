#!/usr/bin/ruby

require 'pathname'
require 'tmpdir'
require 'yaml'

def copy_not_null_array(hexo_yaml_info, hexo_key, docusaurus_yaml_info, docusaurus_key)
  if hexo_yaml_info[hexo_key]
    if hexo_yaml_info[hexo_key].class != Array
      docusaurus_yaml_info[docusaurus_key] = [hexo_yaml_info[hexo_key]]
    else
      docusaurus_yaml_info[docusaurus_key] = hexo_yaml_info[hexo_key]
    end
  end
end

def parse_markdown_file(filepath)
  output_directory_name = "./output"
  text_all = File.read filepath.to_s

  # 分割博文的头部和正文
  begin_split = text_all.index('---')
  unless begin_split
    return
  end
  end_split = text_all.index('---', begin_split + 1)
  head = text_all[0, end_split]
  body = text_all[end_split + 4, text_all.size]

  # 读取YAML头部信息
  temp_filename = File.join(Dir.tmpdir, "yaml_head.temp")
  temp_file = File.new(temp_filename, "w")
  temp_file.puts head
  temp_file.close
  hexo_yaml_info = YAML.load_file(temp_filename)
  File.delete(temp_filename)

  # 迁移所需的YAML信息
  # - Docusaurus文章属性: https://www.docusaurus.cn/docs/blog#header-options
  blog_name = hexo_yaml_info['title'].gsub(/[()]/, '('=>'「', ')'=>'」')

  docusaurus_yaml_info = Hash.new
  docusaurus_yaml_info['authors'] = 'mondaycha' # 在authors.yml中完善信息
  # docusaurus_yaml_info['author_url'] = 'https://github.com/MondayCha'
  # docusaurus_yaml_info['author_image_url'] = 'https://github.com/MondayCha.png'
  # docusaurus_yaml_info['author_title'] = '我逐渐理解了一切（完全没理解）'
  docusaurus_yaml_info['title'] = blog_name
  docusaurus_yaml_info['date'] = hexo_yaml_info['date'].strftime("%Y-%m-%d %H:%M:%S")
  copy_not_null_array(hexo_yaml_info, 'tags', docusaurus_yaml_info, 'tags')
  copy_not_null_array(hexo_yaml_info, 'categories', docusaurus_yaml_info, 'keywords')
  if hexo_yaml_info['photos'] and hexo_yaml_info['photos'][0]
    docusaurus_yaml_info['image'] = hexo_yaml_info['photos'][0]
  end

  # 将新头部和正文写入文件
  unless File.directory? output_directory_name
    Dir.mkdir(output_directory_name, 755)
  end
  create_time = hexo_yaml_info['date'].strftime("%Y-%m-%d") # 时区有问题，待修复
  title = hexo_yaml_info['title']
  output_filename = File.join(output_directory_name, create_time << '-' << blog_name.gsub(' ','-') << '.md')
  if File.file? output_filename
    File.delete(output_filename)
  end
  output_file = File.open(output_filename, 'a+')
  output_file.puts docusaurus_yaml_info.to_yaml

  # 生成摘要，否则缩略页不忍直视
  truncate = "---\n<!--truncate-->"
  output_file.puts truncate
  output_file.puts body
  output_file.close
end


directory_name = "./"
file_list = Pathname.new(directory_name).children.select { |c| c.to_s.match('.*.md$') }
file_list.each do |filepath|
  puts filepath
  parse_markdown_file(filepath)
end