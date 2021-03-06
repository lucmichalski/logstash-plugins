require "./spec/test_utils"

def validate_wowza_fields

  # fields from WOWZA_ACCESS_LOG
  insist { subject['clientip']    } != nil
  insist { subject['ident']       } != nil
  insist { subject['auth']        } != nil
  insist { subject['timestamp']   } != nil
  insist { subject['verb']        } != nil
  insist { subject['request']     } != nil
  insist { subject['httpversion'] } != nil
  insist { subject['response']    } =~ /\A[0-9]*\z/
  insist { subject['bytes']       } =~ /\A[0-9]*\z/
  insist { subject['referrer']    } != nil
  insist { subject['agent']       } != nil
  insist { subject['duration']    } =~ /\A[0-9]*\z/
end

shared_examples "a valid wowza log parser" do

  sample %(89.99.28.243 - 2cf7e6b063 [19/Sep/2014:06:57:05 +0000] "GET /11723021/2014-09-17-1430.mp3?Signature=BanH0VrdfI%2FXCouvXFXivLBS2PE%3D&Expires=1411116501&AWSAccessKeyId=1VYKRTJ5FFKT5B6F4NR2 HTTP/1.1" 304 1000 "-" "AppleCoreMedia/1.0.0.11B554a (iPad; U; CPU OS 7_0_4 like Mac OS X; nl_nl)" 0) do
    insist { subject['tags'] & %w(_grokparsefailure) } == []
    insist { subject['tags'] }.include? 'wowza_access_log'
    insist { subject['tags'] }.include? 'access_log_timestamp'
    insist { subject['tags'] }.include? 'billable'
    insist { subject['tags'] }.include? 'import' unless nil == subject['path']
    insist { subject['bytes'] } == '1000'
    insist { subject['response'] } == '304'
    insist { subject['timestamp'] } == '19/Sep/2014:06:57:05 +0000'
    insist { subject['logsource'] } == 'video-test'

    validate_wowza_fields
  end

  sample %(89.99.23.76 - - [19/Sep/2014:11:39:31 +0200] "GET /10103060?type=live.mp3 HTTP/1.1" 200 17279640 "http://assets.kerkdienstgemist.nl/player/jw6/6.4.3359/jwplayer.flash.swf" "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko" 5754) do
    insist { subject['tags'] & %w(_grokparsefailure) } == []
    insist { subject["tags"] }.include? 'wowza_access_log'

    validate_wowza_fields
  end

end

describe "Wowza filters" do

  extend LogStash::RSpec

  describe "with default config" do
    let(:parse_failure_tag) { '_grokparsefailure'}

    fields \
      'type'      => 'syslog',
      'program'   => 'wowza.access.log',
      'logsource' => 'video-test'

    config [ 'filter{',
      File.read("conf.d/06_import_wowza.conf"),
      File.read("conf.d/60_wowza.conf"),
    '}' ].join

    it_behaves_like "a valid wowza log parser"
  end

  describe "with default config" do
    let(:parse_failure_tag) { '_grokparsefailure'}

    fields \
      'type'  => 'import_wowza',
      'path'      => 'video-test.log'

    config [ 'filter{',
      File.read("conf.d/06_import_wowza.conf"),
      File.read("conf.d/60_wowza.conf"),
    '}' ].join

    it_behaves_like "a valid wowza log parser"
  end

end
