class MonotonePriorityQueue
  def initialize
    @qs = []
    @prio = 0
    @size = 0
  end

  def []=(data, priority)
    raise "non-monotonic add #{priority} vs #{@prio}" if priority < @prio
    (@qs[priority] ||= []) << data
    @size += 1
  end

  def pop
    return nil if @size == 0
    @prio += 1 until (q = @qs[@prio]) && !q.empty?
    @size -= 1
    q.pop
  end
end
