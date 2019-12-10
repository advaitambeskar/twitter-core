#  Contains username_exist(username) which returns {boolean, userid} where userid = [] if boolean is false
#  userid = [userid] if boolean is true
#  Contains isLogin?(username) which returns true or false depending on whether the username is currently
#  logged in

defmodule Project.LoginEngine do
  import Ecto.Query

  def registerUser(username, password) do

    newUser = %Project.Userdata{userid: Ecto.UUID.generate(), username: username, password: password}
    #create the userid that has been generated to
    userid = newUser.userid
    #IO.inspect userid
    {reply, answer} = Project.LoginEngine.username_exist(username)
    if(!reply) do
      Project.Repo.insert(newUser)

      # Follower Database Entry
      followerEntry = %Project.Follower{userid: userid, followers: []}
      Project.Repo.insert!(followerEntry)

      # Feed Database Entry
      feedEntry = %Project.Feed{}
      changeset = Project.Feed.changeset(feedEntry, %{userid: userid, tweets: []})
      Project.Repo.insert!(changeset)

      {:newUser}
    else
      {:oldUser}
    end
  end

  def deleteUser(username, password) do
    #IO.inspect "WEA"
    {reply, userid} = username_exist(username)
    if(reply) do
      #IO.inspect "WER"
      retrieved_password = from(user in Project.Userdata, select: user.password, where: user.username==^username) |> Project.Repo.all
      retrieved_userid = from(user in Project.Userdata, select: user.userid, where: user.username==^username) |> Project.Repo.all
      [uid] = userid
      if(Project.LoginEngine.isLogin?(username)) do
        #IO.inspect "here and there"
        if(retrieved_password = [password]) do
          #IO.inspect "here"
          Project.LoginEngine.logout(username)
          user = Project.Repo.get(Project.Userdata, uid)
          # IO.inspect user
          Project.Repo.delete(user)
          "User #{username} has been successfully deleted."
        else
          "Incorrect password, cannot delete user."
        end
      else
        "You need to login before you delete the user."
      end
    else
      "Sorry, the user you are trying to delete does not exist."
    end
  end

  def username_exist(username) do
    userid = from(user in Project.Userdata, select: user.userid, where: user.username==^username) |> Project.Repo.all
    #IO.inspect userid
    if(userid == []) do
      {false, []}
    else
      {true, userid}
    end
  end

  def isUserNameValid(username) do
    userid = from(user in Project.Userdata, select: user.userid, where: user.username==^username) |> Project.Repo.all
    #IO.inspect userid
    if(userid == []) do
      false
    else
      true
    end
  end


  def login(username, password) do
    retrieved_password = from(user in Project.Userdata, select: user.password, where: user.username==^username) |> Project.Repo.all
    #IO.inspect(retrieved_password)

    if(retrieved_password == [password]) do
      retrieved_userid = from(user in Project.Userdata, select: user.userid, where: user.username==^username) |> Project.Repo.all
      logged_in_Users = Project.LiveUserServer.get_state()
      [uid] = retrieved_userid
      if(Map.has_key?(logged_in_Users, uid)) do
        {:duplicateLogin, username}
      else
        {:loginSuccessful, retrieved_userid}
      end
    else
      {:loginUnsucessful, username}
    end

  end

  def logout(username) do
    userid = from(user in Project.Userdata, select: user.userid, where: user.username==^username) |> Project.Repo.all
    logged_in_Users = Project.LiveUserServer.get_state()

    if userid != [] do
      [uid] = userid

      if(isLogin?(username)) do
        {reply, processid} = Map.fetch(logged_in_Users, uid)

        Process.exit(processid, :kill)
        Project.LiveUserServer.userLogOut(uid)
        "Successfully signed out #{username} of the app."
      else
        "You are trying to log out a user that is not currently logged in."
      end
    else
      "You are attempting to log out a user that does not exist. Please check again"
    end
  end

  def isLogin?(username) do
    retrieved_userid = from(user in Project.Userdata, select: user.userid, where: user.username==^username) |> Project.Repo.all
    [user_id] = retrieved_userid

    logged_in_Users = Project.LiveUserServer.get_state()
    if(Map.has_key?(logged_in_Users, user_id)) do
      true
    else
      false
    end
  end
end
