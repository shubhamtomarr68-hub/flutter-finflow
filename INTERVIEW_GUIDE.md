# FinFlow interview guide

Answers match the code in this repository. If a behavior is not described here, do not claim it in an interview.

## Architecture decisions

1. **Positive amounts plus a direction.** `LedgerEntry.amount` is always greater than zero. Income and expense are a `MoneyDirection`. Totals cannot depend on a negative sign that a form might enter twice.

2. **Pure summary functions.** `MoneySummary` does not read storage or Flutter. Month filters compare year and month. A category chart ignores income. Savings ratio is `null` when income is zero, so the UI does not show `NaN`.

3. **Repository, then a JSON file.** `FinanceRepository` is the only persistence API the cubit knows. The app uses `FileFinanceRepository`. Tests use `MemoryFinanceRepository`. A database can replace the file without changing the pages.

4. **GetIt stays in the composition root.** `configureDependencies()` registers the file repositories. `FinFlowApp` receives those objects and creates the cubits. Widget tests build the app with fakes and do not call GetIt.

5. **Load failure and save failure are different.** A failed load sets `LoadStatus.failure` and the shell shows Retry. A failed save returns an error string and leaves the previous ledger on screen.

## Questions

**Why Cubit instead of Bloc?**
The state transitions are method calls: load, save, filter, change month. There is no event stream to merge. Cubit keeps those methods on one class without an event type per button.

**Where is business logic kept out of widgets?**
Validation is `EntryValidator`. Totals are `MoneySummary`. The cubit writes the snapshot. Pages format numbers and call cubit methods.

**How are dates stored?**
As `yyyy-MM-dd` strings. `DateTime.parse` on a full timestamp can shift the calendar day across timezones. The month chart compares the stored calendar date.

**What does GetIt do here?**
It constructs the two file stores once in `main`. It is not a service locator inside widgets. Tests skip it.

**Are the investments real?**
No. `Holding.lastPrice` is a number saved in the sample JSON. The Investments page says quotes are not live. There is no broker API.

## A hard bug, and the fix

Saving used to be easy to get wrong: if `save` throws, replacing cubit state with an error screen also drops the list the user was editing.

`_persist` writes the new snapshot first. On success it emits the new lists with `LoadStatus.ready`. On failure it returns `Could not save changes.` and does not emit the unsaved lists. The widget test and cubit test both cover this.

## Error handling

- Missing ledger file: write the sample ledger and continue.
- Unsupported JSON `version` or broken JSON: `FormatException` from the repository, then the cubit shows `Could not load your ledger.`
- Invalid form input: the cubit returns a message and does not call `save`.
- Theme file unreadable: `ThemeCubit` falls back to `ThemeMode.system`.

The UI does not print file paths.

## Testing

- `MoneySummary` and `formatInr` for month boundaries and grouping
- `EntryValidator` for empty, zero, and valid input
- `FinanceCubit` for a failed load, a failed save, and a successful add, filter, budget change, and delete
- `FileFinanceRepository` against a temp file, including version 2 rejection
- Widget tests for the balance, the add-form error, retry, and the dark theme

External services are not mocked because there are none. The file repository test uses a real temp file. Widget tests use the memory repository.

## Trade-offs

- A JSON file will get clumsy if the ledger grows into thousands of rows or needs queries. That is acceptable for this sample.
- Holdings are read-only. Editing them would imply a portfolio product this app is not.
- GetIt plus constructor injection is slightly more wiring than constructor injection alone. The split keeps `main` honest and tests simple.
- `fl_chart` is a dependency for one chart. A custom painter would be less code to depend on and more code to maintain.

## What would change in production

- Encrypt the file or store it in a platform secure store if the data were real personal finance data.
- Add authentication before any network sync.
- Replace sample prices with a source you can name, and show the quote timestamp.
- Add migration tests for ledger versions beyond 1.
- Run the app on phone sizes and attach real screenshots.
- Measure test coverage instead of quoting a number from memory.
