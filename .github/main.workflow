workflow "New workflow" {
	on = "pull_request"
	resolves = ["Hello World"]
}

action "Hello World" {
	uses = "./action-b"
	env = {
		MY_NAME = "Mani"
	}
	args = "\"Hello world, I'm $MY_NAME!\""
}