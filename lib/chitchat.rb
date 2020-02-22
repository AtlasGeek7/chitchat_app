@prompt = TTY::Prompt.new
@cursor = TTY::Cursor

$client = nil
$message = []
$user = ''
$online = false
$user_cnt = 0
$msg_cnt = 0
def connect_to_db
  $client = Mysql2::Client.new(:host => "sql9.freemysqlhosting.net", :username => "sql9323521", :password => "WgmexVI9VE", :database => "sql9323521", :port => "3306")
end

def close_db
  $client.close
end

def clrscrn
   system('cls')
end

def disp_logo
  pastel = Pastel.new
  font = TTY::Font.new(:doom)
  print pastel.yellow(font.write("              Welcome  to  ChitChat!  "))
  puts ""
end

def disp_users
  disp_logo
  results = $client.query("SELECT * FROM users")
  rows = []
  max = 10
  results.each_with_index { |row,idx|
    len = row['username'].size
    if (len >= max)
      max = len + 1
    end
    if (row['status'] == 1)
      row['status'] = "    \u2022    ".colorize(:green).colorize( :background => :white)
    else
      row['status'] = "    \u2022    ".colorize(:red).colorize( :background => :white)
    end
    rows << [' ' + row['username'].capitalize().strip , row['status']]
    rows << :separator if idx < results.size-1
    if row["dne"]
      puts row["dne"]
    end
  }
  formatted_rows = []
  rows.each_with_index { |r,i|
    if (i % 2 == 0)
      if (r[0].size == max)
        white_space = ' '
      else
        white_space = ' ' * (max + 1 - r[0].size)
      end
      formatted_rows << [ (r[0] + white_space).colorize(:black).colorize( :background => :white), r[1].colorize( :background => :white) ]
    else
      formatted_rows << r
    end
  }
  table = Terminal::Table.new :headings => [(' Username:' + ' ' * (max - 9)).colorize(:black).colorize( :background => :white), ' Status: '.colorize(:black).colorize( :background => :white)], :rows => formatted_rows
  puts table
  puts ""
end

def disp_msg
  $message = []
  results = $client.query("SELECT * FROM users WHERE username='ADMIN'")
  rows = []
  results.each_with_index { |row,idx|
    $message << row['message']
    if row["dne"]
      puts row["dne"]
    end
  }
  $msg_cnt = $message.size
  message = $message[0].split('~')
   puts message[-10..-1]
  return $message
end

def login
  #puts "Login"
  user = @prompt.ask("Username: ").capitalize()
  pass = @prompt.mask("Password: ")
  results = $client.query("SELECT * FROM users WHERE username='#{user.upcase}' AND password='#{pass}'")
  $user_count = results.count
  if (results.count == 1)
    puts "Welcome, #{user}!"
    $user = user
    results = $client.query("UPDATE users SET status='1' WHERE username='#{user}'")
    clrscrn

    $online = true
  else
    puts "Invalid credentials!"
    # "Wrong username/password combination."
    login
  end
end

def signup()
  user = @prompt.ask("Username: ")
  results = $client.query("SELECT * FROM users WHERE username='#{user.upcase}'")
  if (results.count == 0)
    pass_one = @prompt.mask("Password: ")
    pass_two = @prompt.mask("Password: ")
    return [user,pass_one,pass_two]
  else
    puts "Username unavailabe!"
    signup
  end
end

def validate_signup
  arr = signup()
  user = arr[0]
  password_one = arr[1]
  password_two = arr[2]
    if password_one == password_two
      puts "Congrats, #{user}!"
      online = 1
      message = "Welcome to ChitChat!"
      results = $client.query("INSERT INTO users(username,password,message,status,reg_date) VALUES('#{user.upcase}','#{password_one}','#{message}','#{online}','#{Time.now}')")
      puts "Login: "
      login
    else
      puts "Password mismatch!"
      validate_signup
    end
end

def menu
  clrscrn
  pastel = Pastel.new
  font = TTY::Font.new(:doom)
  print pastel.yellow(font.write("              Welcome  to  ChitChat!  "))
  puts ""
  puts "Main menu: "
  connect_to_db
  input = @prompt.select("", ["1.Sign up", "2.Login", "3.Quit"])
  case input
  when "1.Sign up"
    validate_signup
  when "2.Login"
    login
  else
    exit
  end
end

def disp_msg_box
  Curses.init_screen
  #my_str = "LOOK! PONIES!"
  my_str = "Your message: "
  height, width = 12, 80 #my_str.length + 10
  top, left = (Curses.lines - height) / 2, (Curses.cols - width) / 2
  bwin = Curses::Window.new(height, width, top, left)
  bwin.box("\\", "/")
  bwin.refresh
  win = bwin.subwin(height - 4, width - 4, top + 2, left + 2)
  win.setpos(2, 3)
  win.addstr(my_str)# or even

  #win << "\nOH REALLY?"
  #win << "\nYES!! " + my_str
  win.refresh
  #win.getch
  str = win.getstr
  win.close
  Curses.close_screen
  return str
end

def logout
  results = $client.query("UPDATE users SET status='0' WHERE username='#{$user}'")
  close_db
  $online = false
end

loop do
  user_message = ''
  disp_users
  disp_msg
  puts ""
  char = @prompt.keypress("Press spacebar to type a message: (while curser is still blinking in same line)".colorize(:yellow), keys: [:space], timeout: 10)
  if (char != nil)
    user_message = disp_msg_box.chomp.strip
    char = ''
  end
  if (user_message != '')
    if (user_message.downcase == "$off")
      system('cls')
      sleep 3
      logout
    else
      message = $message[0] + "\n[#{Time.now.strftime("%b-%m-%d %H:%M:%S")}(CT)] ".colorize(:green) + "#{$user} says: #{user_message}~"
      escaped = $client.escape(message)
      results = $client.query("UPDATE users SET message='#{escaped}' WHERE username='ADMIN'")
      message = ''
    end
  end
  break if !$online
  puts "Updating...".colorize(:green)
  sleep 1
  clrscrn
end
