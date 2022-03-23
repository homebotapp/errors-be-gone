# errors-be-gone
## Ensuring our QA is a great as we are.

### Prerequisites:
There is a way for this to be done automatically... but I haven't looked into how just yet.
Prior to running you will need Ruby installed on your machine.
I believe you will also need the gem file **Colorize** installed. To install **Colorize** run: ```sudo gem install colorize```

## How To
- To run the program open up terminal navigate to the project directory, run `ruby qa.rb`
  - You must navigate to the *errors-be-gone* file within terminal. To do this use ```cd```. Your terminal instance must be within the same folder as the qa.rb file.
  - [Basic Terminal Article] (https://computers.tutsplus.com/tutorials/navigating-the-terminal-a-gentle-introduction--mac-3855)

- The program has two specific modes that can be initiated when running the program.
- ```ruby qa.rb -a``` will run the program in **Archive** mode. Archive mode will include a text file that contains information needed when added files to the archive.
- ```ruby qa.rb -o``` will run the program in **Override** mode. Override mode is a modified version of archive mode. In archive mode, the text file is only printed out when there are **no** errors in any of the files. Override mode allows the text file to be printed out even when there are errors. This mode can be useful if you don't care about the issues being thrown out - or are unable to fix the issues and want to continue.
