## Dan's Script Library

This is a collection of some of the various automation and administration PowerShell scripts written over the years.

### Password Generator
Randomly generated passwords are often simply a jumble of random characters. They're difficult to remember and, as such, people forget them or store them somewhere, frequently insecurely. For service desks, they're difficult to read out to someone over the phone. This function was designed to create secure, passwords that are easier to remember and simple to communicate.

The source word list contains ~1100 words of three characters or more. All obviously unsuitable words have been removed, and the list scanned for obvious homophones - words that are spelled differently but sound the same, e.g. *reign* and *rain*, or *hear* and *here*. The password contains three main elements; one word in upper case letters, one in lower case letters and a number. These three elements are combined in a random order, and separated with a random symbol.

Optionally, the script can use OpenAI to check if the words chosen are inappropriate, either individually or together. For instance, **Happy** and **Dream** are appropriate to combine. **Happy** and **Ending** would not be. Use of the OpenAI function is dependent on having an OpenAI API subscription and providing the function with the API key.
