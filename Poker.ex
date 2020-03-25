# royal flush: 1
# straight flush: 2
# four of a kind: 3
# full house: 4
# flush: 5
# straight: 6
# three of a kind: 7
# two pair: 8
# pair: 9
# high card: 10

defmodule Poker do

#deal function iterates through cards and generates two hands of 5 cards in each
	def deal(list) when length(list) !== 10 do
		:error
	end
    def deal(list) do
		deal(list, [], [],0)
	end
	def deal(_,player1,player2,10) do
		generateRanksAndSuits(player1, player2)
	end
	def deal(list, player1, player2, i) do
		if (rem(i,2)== 0), do: deal((tl list), player1 ++ [hd list], player2, i+1), else: deal((tl list), player1, player2 ++ [hd list], i+1)
	end

#accepts a list of numbers and generates two sorted lists of cards with ranks and suits:
#INPUT: [1,2,3,4,5]
#OUTPUT: ["1C", "2C", "3C", "4C", "5C"]
	def generateRanksAndSuits(player1,player2) do
		new1 = Enum.map(player1, &(change_card_representation(&1)))
		new2 = Enum.map(player2, &(change_card_representation(&1)))

		sorted1 = Enum.sort(new1, &((hd Tuple.to_list(Integer.parse(&1))) <= (hd Tuple.to_list(Integer.parse(&2)))))
		sorted2 = Enum.sort(new2, &((hd Tuple.to_list(Integer.parse(&1))) <= (hd Tuple.to_list(Integer.parse(&2)))))

		showPlayers(sorted1, sorted2)
	end

#generates a card from a single number
#INPUT: 32
#OUTPUT: 6H
	def change_card_representation(card) do
		case card do
			card when card in 1..13 -> Integer.to_string(rem(card,14)) <> "C"
			card when card in 14..25 -> Integer.to_string(rem(card,13)) <> "D"
			card when card in 27..38 -> Integer.to_string(rem(card,13)) <> "H"
			card when card in 40..51 -> Integer.to_string(rem(card,13)) <> "S"
			card when card === 26 -> Integer.to_string(13) <> "D"
			card when card === 39 -> Integer.to_string(13) <> "H"
			card when card === 52 -> Integer.to_string(13) <> "S"
			_ -> card
		end
	end

#Makes a map that contains two sorted hands of cards - hand1 and hand1 - and
#the numerical representation of each hand ranking. Numerical representations are provided 
#at the very top of this program
# I.e :straight -> 6
# :full_house -> 4 
	def showPlayers(player1,player2) do
		rank1 = score_hand(player1)
		rank2 = score_hand(player2)
		stats = %{hand1: player1, ranking1: rank1, hand2: player2, ranking2: rank2}
		getWinner(stats)
	end

#Decides hand ranking.
#Output is a tuple that holds hand ranking as a first element and 
#the value of a greatest rank as a second argument (for tie breaking)
	def score_hand(list) do
		difference = calculateDiff(list)
		stats = getRanksAndTheirFrequencies(list, false)

		cond do
			royalFlush?(list) -> {1, stats}
			allEqualSuits?(list) and -1 === difference and allNumbersInCountingSequence?(list) -> {2,stats}
			allEqualSuits?(list) and not (-1 === difference) -> {5, stats} 
			not(allEqualSuits?(list)) and -1 === difference and allNumbersInCountingSequence?(list) -> {6, stats}
			true -> getRanksAndTheirFrequencies(list, true)
		end
	end

#Iterate over list of cards and return a list of card ranks or frequencies.
#If flag == true -> the function returns a list that represents frequencies of each rank (needed for pair matching)
#If flag == false -> return the greatest card value in hand
	def getRanksAndTheirFrequencies(list, flag) do
		getRanksAndTheirFrequencies(list, flag, [])
	end
	def getRanksAndTheirFrequencies([],flag,acc) do
		getFrequencies(acc,flag)
	end
	def getRanksAndTheirFrequencies(list, flag, acc) do
		getRanksAndTheirFrequencies((tl list), flag, acc ++ [hd Tuple.to_list(Integer.parse(hd list))])
	end	

	def getFrequencies(list, flag) do
		if flag do
			frequencies = list |> Enum.reduce(%{}, fn x, acc -> Map.update(acc, x, 1, &(&1 + 1)) end)
			score_hand_pairs(frequencies)
		else
			map_keys = list |> Enum.reduce(%{}, fn x, acc -> Map.update(acc, x, 1, &(&1 + 1)) end) |> Map.keys
			if 1 in map_keys do
				14
			else 
				map_keys |> Enum.max
			end
		end
	end

#Using output (card frequencies) from the previous function, we perform pattern matching in order to
#get the right hand ranking.
#I.e, if a hand ranking 
	def score_hand_pairs(list) do
		case Enum.sort(Map.values(list)) do
			[1,4] -> {3, list |> Enum.find(fn {_, val} -> val == 4 end) |> elem(0)}
			[2,3] -> {4, list |> Enum.find(fn {_, val} -> val == 3 end) |> elem(0)}
			[1,1,3] -> {7, list |> Enum.find(fn {_, val} -> val == 3 end) |> elem(0)}
			[1,2,2] -> {8, list |> Enum.filter(fn {_, val} -> val == 2 end) |> Enum.max_by(fn {key,_} -> key end) |> elem(0)}
			[1,1,1,2] -> {9, list |> Enum.find(fn {_, val} -> val == 2 end) |> elem(0)}
			[1,1,1,1,1] -> {10, list |> Enum.map(fn {key, _} -> key end) |> Enum.max}
		end
	end

# ===== Tie Breaking starts here =====

#If one's hand rank is greater than the other's, return the winning hand
#else, we move to deciding a winner based on the higher card 
	def getWinner(stats) do
		cond do
			((stats.ranking1 |> elem(0)) < (stats.ranking2 |> elem(0))) -> stats.hand1
			((stats.ranking1 |> elem(0)) > (stats.ranking2 |> elem(0))) -> stats.hand2
			true -> getWinnerByHigherCard(stats)
		end
	end

#Decide if there's a winner by next higher card.
#If not, we switch to the next higher cards in both hands. 
	def getWinnerByHigherCard(stats) do 
		ranking_hand1 = getRanks(stats.hand1)
		ranking_hand2 = getRanks(stats.hand2)
		cond do
			(stats.ranking1 |> elem(1)) === 1 and not((stats.ranking2 |> elem(1)) === 1) -> stats.hand1
			(stats.ranking2 |> elem(1)) === 1 and not((stats.ranking1 |> elem(1)) === 1) -> stats.hand2

			(stats.ranking1 |> elem(1)) > (stats.ranking2 |> elem(1)) -> stats.hand1
			(stats.ranking1 |> elem(1)) < (stats.ranking2 |> elem(1)) -> stats.hand2
			true -> getWinnerByNextHigherCard(stats, ranking_hand1 -- [Enum.max(ranking_hand1)], ranking_hand2 -- [Enum.max(ranking_hand2)])
		end
	end

#Recursively decide who's the winner based on the highest card until both hands have no cards left
	def getWinnerByNextHigherCard(stats, hand1, hand2) when length(hand1) !== 0 and length(hand2) !== 0  do
		cond do
			Enum.max(hand1) > Enum.max(hand2) -> stats.hand1
			Enum.max(hand1) < Enum.max(hand2) -> stats.hand2
			true -> getWinnerByNextHigherCard(stats, hand1 -- [Enum.max(hand1)], hand2 -- [Enum.max(hand2)])
		end
	end

	def getWinnerByNextHigherCard(stats, hand1,hand2) when length(hand1) === 0 and length(hand2) === 0 do
		getWinnerBySuit(stats)
	end

#Ok, game's getting pretty desperate at this point. 
#The winner is declared upon the suit of the highest cards in both hands.
# C < D < H < S
	def getWinnerBySuit(stats) do
		getWinnerBySuit(stats, stats.hand1, stats.hand2)
	end

	def getWinnerBySuit(stats, hand1,hand2) when length(hand1) !== 0 and length(hand2) !== 0 do
		hand1_greatest_suit = List.last(stats.hand1) |> String.last
		hand2_greatest_suit = List.last(stats.hand2) |> String.last

		cond do
			hand1_greatest_suit < hand2_greatest_suit -> stats.hand2
			hand1_greatest_suit > hand2_greatest_suit -> stats.hand1
			true -> getWinnerBySuit(stats, [], [])
		end
	end

	def getWinnerBySuit(_, hand1, hand2) when length(hand1) === 0 and length(hand2) === 0 do
		"Tie breaking can't handle these combinations"
	end

# ====== Helper functions ======

	def allEqualSuits?(list) do
		Enum.all?(list, &(String.last(&1)) == String.last(hd list))
	end

	def calculateDiff(list) do
		(hd Tuple.to_list(Integer.parse(hd list))) - (hd Tuple.to_list(Integer.parse(hd(tl list))))
	end

	def allNumbersInCountingSequence?(list) do
		ranks = Enum.map((tl list), fn x -> (hd Tuple.to_list(Integer.parse(x))) end)
		if (hd ranks) - (hd(tl ranks)) === -1 and	
			(hd (tl ranks)) - (hd(tl (tl ranks))) === -1 and
			(hd(tl (tl ranks))) - (hd(tl(tl(tl ranks)))) === -1  do
			true
		else 
			false
		end
	end

	def getRanks(list) do
		getRanks(list, [])
	end
	def getRanks([],acc) do
		acc
	end
	def getRanks(list, acc) do
		getRanks((tl list), acc ++ [hd Tuple.to_list(Integer.parse(hd list))])
	end

#Royal Flush is a special case combination
	def royalFlush?(list) do
		["1C", "10C", "11C", "12C", "13C"] == list || 
		["1D", "10D", "11D", "12D", "13D"] == list ||
		["1H", "10H", "11H", "12H", "13H"] == list ||
		["1S", "10S", "11S", "12S", "13S"] == list 
	end
end
