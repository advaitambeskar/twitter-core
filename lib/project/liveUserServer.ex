defmodule Project.LiveUserServer do
  use GenServer

  @processName :"LiveUserServer"

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @processName)
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

  def userLogedIn(userid, pid) do
    processID = Process.whereis(@processName)
    GenServer.call(processID, {:userLoggedIn, userid, pid})
  end

  def userLogOut(userid) do
    processID = Process.whereis(@processName)
    GenServer.call(processID, {:userLoggedOut, userid})
  end

  def get_state() do
    pid = Process.whereis(@processName)
    GenServer.call(pid, :getState)
  end

#  def getLiveServerProcessId() do
#    Process.whereis(@processName)
#  end

  def handle_call({:userLoggedOut, userid}, _from, state) do
    map = state
    # IO.inspect map
    map = Map.delete(map, userid)
    {:reply, "Updating State", map}
  end

  def handle_call({:userLoggedIn, userid, pid}, _from, state) do
    map = state
    map = Map.put(map, userid, pid)
    #     IO.inspect(map)
    {:reply, "Updated live users", map}
  end

  def handle_call(:getState, _from, state) do
    {:reply, state, state}
  end

end

