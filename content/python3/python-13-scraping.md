+++
title = "Web scraping"
slug = "python-13-scraping"
weight = 13
+++

<!-- Marie's Web scraping with Python https://mint.westdri.ca/python/ws_webscraping -->

*Web scraping* refers to extracting data from the web in a semi-automatic fashion. There is some programming
involved, but Python web-scraping tools attempt to make this as painless as possible.

```py
import requests                 # to download the html data from a site
from bs4 import BeautifulSoup   # to parse these html data
import pandas as pd             # to store our data in a dataframe

url = "https://arxiv.org/list/econ/new"
r = requests.get(url)
r   # <Response [200]> means our request was successful

print(r.text[:200])   # the first 200 characters in the raw data

mainpage = BeautifulSoup(r.text, "html.parser")
mainpage.prettify()   # still very messy ...
```

There is a lot of text there, and it's not particularly readable even after `.prettify()`! At this point we
need to identify relevant markers in the HTML from which we could extract interesting data. There are several
ways of doing this, e.g. you can use [SelectorGadget](https://selectorgadget.com) bookmarklet on your site and
mouse over various elements on the page, but here I will just look at the HTML source.

In Firefox I load https://arxiv.org/list/econ/new, select **Tools** | **Browser Tools** | **Page Source** and
then try to identify relevant tags. For example, I might see some useful text inside the `<div>` container
tag:

```txt
<div class="list-title mathjax">
<span class="descriptor">Title:</span> This is the first article's title
</div>
```

Let's search for all `<div>` tags with an attribute `class` starting with "list-title":

```py
divs = mainpage.findAll("div", attrs={'class':'list-title'})
len(divs)   # number of article titles on this page
```

Let's inspect the first title:

```py
div[0]
div[0].text           # get the actual text inside this container
div[0].text.strip()   # remove leading and trailing whitespaces and end-of-line characters
div[0].text.strip().replace('Title: ', '')
```

We can wrap this in a loop through all titles:

```py
for div in divs:
    print(div.text.strip().replace('Title: ', ''))
```

Let's store our data in a dataframe with three columns:

```py
titles = []
divs = mainpage.findAll("div", attrs={'class':'list-title'})
for div in divs:
    titles.append(div.text.strip().replace('Title: ', ''))

authors = []
divs = mainpage.findAll("div", attrs={'class':'list-authors'})
for div in divs:
    authors.append(div.text.strip().replace('Authors:', '').replace('\n', ''))

subjects = []
divs = mainpage.findAll("div", attrs={'class':'list-subjects'})
for div in divs:
    subjects.append(div.text.strip().replace('Subjects: ', ''))

d = {'titles': titles, 'authors': authors, 'subjects': subjects}
papers = pd.DataFrame(d)
papers
```

Finally, let's filter articles based on a topic:
```py
mask = ["Machine Learning" in subject for subject in papers.subjects]
papers[mask]
```

{{< question num=13.1 >}}
Create a list of abstracts from today's articles on https://arxiv.org/list/econ/new -- no titles, authors,
keywords, just abstracts. Print the first 5 elements of this list. Paste the entire Python code to do this
from start to finish.
{{< /question >}}

<!-- ```py -->
<!-- import requests                 # to download the html data from a site -->
<!-- from bs4 import BeautifulSoup   # to parse these html data -->
<!-- import pandas as pd             # to store our data in a dataframe -->

<!-- url = "https://arxiv.org/list/econ/new" -->
<!-- r = requests.get(url) -->
<!-- mainpage = BeautifulSoup(r.text, "html.parser") -->

<!-- info = mainpage.findAll("p", attrs={'class':'mathjax'}) -->
<!-- abstracts = [] -->
<!-- for i in info: -->
<!--     abstracts.append(i.text.strip().replace("\n", " ")) -->

<!-- abstracts[:5] -->
<!-- ``` -->
