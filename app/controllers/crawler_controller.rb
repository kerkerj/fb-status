class CrawlerController < ApplicationController
  before_action :check_temp_total_count

  def index
    # see: http://getbootstrap.com/components/#progress
    url_color = [
      'progress-bar-success',
      'progress-bar-info',
      'progress-bar-danger',
      'progress-bar-info'
    ]

    target_url = [
      'https://www.facebook.com/pages/無限期支持方仰寧支持警察/310212962461242',
      'https://www.facebook.com/pages/方仰寧加油/1422073471381129?fref=ts',
      'https://www.facebook.com/antiblacktw?fref=ts',
      'https://www.facebook.com/peoplewithpeople?fref=ts'
    ]

    urls = target_url.join("','")

    @response = Fql.execute("SELECT comments_fbid, comment_count, like_count, share_count, click_count, total_count, normalized_url FROM link_stat WHERE url IN ('#{urls}')")

    @response.each_index do |index|
      report_data = @response[index]
      report_data_key = report_data['normalized_url']
      old_total_count = session[:temp_total_count][report_data_key].to_i

      report_data['query_at'] = Time.now.to_s
      report_data['page_title'] = get_page_title_by_url(report_data['normalized_url'])
      report_data['count_diff'] = report_data['total_count'].to_i - old_total_count;
      report_data['percent'] = (report_data['count_diff'] / 250.0 * 100).round
      report_data['url_color'] = url_color[index].present? ? url_color[index] : ''

      session[:temp_total_count][report_data_key] = report_data['total_count']
    end

    render layout: false
  end

  private

  def check_temp_total_count
    session[:temp_total_count] = {} if session[:temp_total_count].blank?
  end

  def get_page_title_by_url ( url )
    page_title = url.match(/pages\/([^\/]+)\//)
    page_title = url.match(/com\/([^\/]+)[\/\?]/) if page_title.blank?

    if (page_title.nil?)
      title = '未取得標題'
    else
      title = page_title[1]

      if (page_title[1] == 'peoplewithpeople')
        title = '因為支持警察，所以我反對方仰寧'
      elsif (page_title[1] == 'antiblacktw')
        title = '反黑箱服貿協議'
      end
    end

    return title
  end
end
