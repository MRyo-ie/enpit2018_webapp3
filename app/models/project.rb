class Project < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  has_many :github_commit_logs, foreign_key: :project_id

  belongs_to :user, foreign_key: :users_id


  # commit数：ヤギのエサの量を更新する
  def update_commit_num()
    ###  ヤギが食べる  ###
    if self.user.email == "e165738@ie.u-ryukyu.ac.jp"
      self.commit_num -= self.goat_eat_speed
    end

    ###  エサを追加  ###
    @new_commit_logs = JSON.parse(`curl https://api.github.com/repos/#{self.user.username}/#{self.name}/commits`)
    # webhook までのつなぎ。
    # 30までしか取得できないため、30以上は追加できない。
    added_commit_num = get_added_commit_num(@new_commit_logs)
    self.commit_num += added_commit_num
    # github_commit_log を差分更新
    save_commit_log(commit_logs[0, added_commit_num])

    ###  0以下は 0にする。  ###
    if self.commit_num < 0
      self.commit_num = 0
    end
    self.save
  end
  

  def get_added_commit_num(commit_logs)
    return 0 if commit_logs.class != Array  # ないと思うけど一応。
    # 新 → 旧　の順。
    counter = 1
    for log in commit_logs do
      if log.commit_id == self.newest_commit_id
        break
      end
      counter += 1
    end
    return counter
  end

  def save_commit_log(commit_logs)
    #print()
    #print(commit_logs)
    #print()
    return 0 if commit_logs.class != Array
    for log in commit_logs do
      params = choose_log_data(log)
      github_commit_logs = GithubCommitLog.new(params)
      github_commit_logs.save
    end
    # 最新（最初）の commit の id をメモする
    self.newest_commit_id = commit_logs[0]['sha']
    self.save
    puts("\nself.newest_commit_id : #{self.newest_commit_id}\n")
  end

  def choose_log_data(log)
    # ここをいじると DB の内容が変わるので、github_commit_log を create し直す必要あり。
    #   → 一括更新するメソッド書いた：rake init_github_commit_log:init 
    params = {}
    params['id'] = log['id']  # ?
    params['commit_id'] = log['sha']
    params['message'] = log['commit']['message'][0, 244]  # 文字数上限を追加。
    params['users_id'] = self.user.id
    params['project_id'] = self.id
    # テスト用
    #params['name'] = log['committer']['date']
    return params
  end
end
