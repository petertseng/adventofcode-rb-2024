require_relative 'priority_queue'

module Search
  module_function

  def paths_of(prevs, n)
    return [[n]] if !prevs.has_key?(n) || !(prev = prevs[n])
    prev.flat_map { |x|
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

  def bfs(starts, num_goals: 1, neighbours:, goal:, verbose: false, multipath: false)
    current_gen = starts.dup
    prev = starts.to_h { |s| [s, nil] }
    goals = {}
    gen = -1

    until current_gen.empty?
      gen += 1
      next_gen = []
      while (cand = current_gen.shift)
        if goal[cand]
          goals[cand] = gen
          if goals.size >= num_goals
            next_gen.clear
            break
          end
        end

        neighbours[cand].each { |neigh|
          # can't use &. because nil
          if prev.has_key?(neigh)
            next if prev[neigh].frozen?
            prev[neigh] << cand
          else
            prev[neigh] = [cand]
            prev[neigh].freeze unless multipath
            next_gen << neigh
          end
        }
      end
      next_gen.each { |c| prev[c].freeze }
      current_gen = next_gen
    end

    {
      found: !goals.empty?,
      gen: gen,
      goals: goals.freeze,
      prev: prev.freeze,
    }.merge(verbose ? {paths: goals.to_h { |goal, _gen| [goal, send(multipath ? :paths_of : :path_of, prev, goal)] }.freeze} : {}).freeze
  end
end
