# RepCount

A simple command-line tool to track your workout sets and reps so you never lose count! 💪

## Features

- ✅ Track multiple exercises in a single workout session
- ✅ Log sets and reps for each exercise
- ✅ View real-time progress during your workout
- ✅ Save completed workouts to history
- ✅ Simple, fast command-line interface
- ✅ No dependencies required (pure Python)

## Installation

1. Clone this repository:
```bash
git clone https://github.com/ermakj1/RepCount.git
cd RepCount
```

2. Make the script executable (Linux/Mac):
```bash
chmod +x repcount.py
```

3. Optionally, create an alias for easier access:
```bash
alias repcount='python3 /path/to/RepCount/repcount.py'
```

## Usage

### Start a new workout
```bash
python3 repcount.py start
```

### Log a set
```bash
python3 repcount.py add <exercise> <reps>
```

Examples:
```bash
python3 repcount.py add pushups 20
python3 repcount.py add squats 15
python3 repcount.py add pullups 10
```

### Check your progress
```bash
python3 repcount.py status
```

### Complete your workout
```bash
python3 repcount.py done
```

## Complete Example Workout

```bash
# Start your workout
$ python3 repcount.py start
✓ New workout session started!
  Started at: 02:30 PM

# Log your first exercise
$ python3 repcount.py add pushups 20
✓ pushups: Set 1 - 20 reps logged
  Total: 1 sets, 20 reps

# Continue logging sets
$ python3 repcount.py add pushups 18
✓ pushups: Set 2 - 18 reps logged
  Total: 2 sets, 38 reps

# Add different exercises
$ python3 repcount.py add squats 15
✓ squats: Set 1 - 15 reps logged
  Total: 1 sets, 15 reps

# Check your progress anytime
$ python3 repcount.py status

==================================================
CURRENT WORKOUT SESSION
==================================================
Started: 02:30 PM

pushups:
  Set 1: 20 reps
  Set 2: 18 reps
  → Total: 2 sets, 38 reps

squats:
  Set 1: 15 reps
  → Total: 1 sets, 15 reps

==================================================

# Finish your workout
$ python3 repcount.py done

✓ Workout completed and saved to history!

Workout Summary:
  pushups: 2 sets, 38 reps
  squats: 1 sets, 15 reps

Overall: 3 total sets, 53 total reps
Duration: 15 minutes
```

## Commands

| Command | Description |
|---------|-------------|
| `start` | Start a new workout session |
| `add <exercise> <reps>` | Log a set for an exercise |
| `status` | View current workout progress |
| `done` | Complete and save the workout |
| `help` | Show usage instructions |

## Data Storage

- **Current workout**: Stored in `current_workout.json` (auto-saved after each set)
- **Workout history**: Saved in `workout_history.json` when you complete a workout
- Both files are created automatically in the current directory

## Requirements

- Python 3.6 or higher
- No external dependencies required

## License

MIT License - Feel free to use and modify!
