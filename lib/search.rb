require_relative 'priority_queue'

module Search
  module_function

  def paths_of(prevs, n)
    return [[n]] if !prevs.has_key?(n)
    prevs[n].flat_map { |x|
      paths_of(prevs, x).map { |y| y + [n] }
    }
  end

  def path_of(prevs, n)
    path = [n]
    current = n
    while (current = prevs[current]&.[](0))
      path.unshift(current)
    end
    path.freeze
  end

  def astar(starts, neighbours, heuristic, goal, verbose: false, multipath: false)
    g_score = Hash.new(1.0 / 0.0)
    starts.each { |start| g_score[start] = 0 }

    closed = {}
    open = MonotonePriorityQueue.new
    starts.each { |start| open[start] = heuristic[start] }
    prev = {}

    while (current = open.pop)
      next if closed[current] # safe if heuristic is monotone
      closed[current] = true

      return [g_score[current], send(multipath ? :paths_of : :path_of, prev, current)] if goal[current]

      neighbours[current].each { |neighbour, cost|
        next if closed[neighbour]
        tentative_g_score = g_score[current] + cost
        next if tentative_g_score > g_score[neighbour]

        if verbose
          if !multipath || tentative_g_score < g_score[neighbour]
            prev[neighbour] = [current]
          else
            prev[neighbour] << current
          end
        end
        next if tentative_g_score == g_score[neighbour]

        g_score[neighbour] = tentative_g_score
        open[neighbour] = tentative_g_score + heuristic[neighbour]
      }
    end

    nil
  end
end
