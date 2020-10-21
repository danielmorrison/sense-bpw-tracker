# Sense/Holland BPW EV Rate Comparison

This takes exports from [Sense](https://www.sense.com) and shows what your savings would be under [Holland BPW's EV Time of Use Rate](https://hollandbpw.com/en/customer-service/residential/residential-rates#tou)

## How to use

### Get Data from Sense

1. Go to https://home.sense.com/trends
2. Select a month
3. Click the icon in the upper right that sort of looks like sharing
4. Select "Hour" for the interval.

## Config and run

1.  Set `data_root` to where you put these files.
2. `ruby calculate.rb`
3. Look at the results. Positive numbers are "savings". Is that how it should be? PRs welcome. ;)
