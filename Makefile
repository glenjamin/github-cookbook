test : rubocop foodcritic kitchen

check : rubocop foodcritic

rubocop :
	rubocop .

foodcritic :
	foodcritic -P -f any .

kitchen :
	kitchen test

.PHONY:
	test check rubocop foodcritic kitchen
