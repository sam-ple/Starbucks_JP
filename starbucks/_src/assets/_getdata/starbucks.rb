require 'nokogiri'
require 'open-uri'

# ベースURL
base_url = "https://store.starbucks.co.jp/detail-"

# 店舗番号の範囲を指定
start_number = 1
end_number = 500

# 出力ファイル名
output_file = "starbucks_stores_#{start_number}_#{end_number}.md"

# データ収集
stores = []

(start_number..end_number).each do |store_number|
  puts "取得中: 店舗番号 #{store_number}..."
  url = "#{base_url}#{store_number}/"

  begin
    # ページを取得
    doc = Nokogiri::HTML(URI.open(url))

    # 店名の取得
    name = doc.at_css('.store-detail__title-text')&.text&.strip

    # 住所の取得
    raw_address = doc.at_css('.store-detail__text-detail.line-height-22')&.text&.strip
    # 住所の郵便番号と全角スペースを削除
    address = raw_address&.sub(/^\d{3}-\d{4}　/, '')

    # 都道府県名の取得（最初の半角スペースまで）
    prefecture = address&.split(" ")&.first

    # 店舗情報リンクの生成（店舗名にリンクを付与）
    store_info_link = "<a href=\"#{base_url}#{store_number}/\" target=\"_blank\">#{name}</a>"

    # Googleマップリンクの生成（住所にリンクを付与）
    map_link = "<a href=\"https://www.google.com/maps/search/スターバックス+コーヒー+#{name}\" target=\"_blank\">#{address}</a>"

    # スタンプリンクの生成
    stamp_url = "<a href=\"https://www.starbucks.co.jp/mystarbucks/mystore/images/stamp/#{store_number}.png\" target=\"_blank\">スタンプ</a>"

    # 店舗が存在しない場合は次の番号へ
    if name.nil? || address.nil? || prefecture.nil?
      puts "店舗番号 #{store_number}: 情報が見つかりませんでした。"
      next
    end

    # データ格納
    stores << {
      店舗番号: store_number,
      都道府県: prefecture,
      店舗名: store_info_link,
      住所: map_link,
      スタンプ: stamp_url
    }

    # サーバーへの負荷軽減のための待機
    sleep(rand(5..10))

  rescue OpenURI::HTTPError => e
    puts "店舗番号 #{store_number} は存在しないか、アクセスに失敗しました: #{e.message}"
    next
  end
end

# Markdown形式でファイル保存
File.open(output_file, 'w') do |file|
  file.puts "| 店舗番号 | 都道府県 | 店舗名 | 住所 | スタンプ |"
  file.puts "|---|---|---|---|---|"
  stores.each do |store|
    file.puts "| #{store[:店舗番号]} | #{store[:都道府県]} | #{store[:店舗名]} | #{store[:住所]} | #{store[:スタンプ]} |"
  end
end

puts "Markdownファイル '#{output_file}' が作成されました！"
