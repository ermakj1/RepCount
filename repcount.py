#!/usr/bin/env python3
"""
RepCount - A simple workout set and rep counter
Helps you track your workout sets and reps so you don't lose count.
"""

import json
import os
import sys
from datetime import datetime
from typing import Dict, List, Optional


class WorkoutSession:
    """Manages a workout session with exercises, sets, and reps."""
    
    def __init__(self, session_file: str = "current_workout.json"):
        self.session_file = session_file
        self.exercises: Dict[str, List[int]] = {}
        self.start_time: Optional[str] = None
        self.load_session()
    
    def load_session(self):
        """Load existing workout session from file."""
        if os.path.exists(self.session_file):
            try:
                with open(self.session_file, 'r') as f:
                    data = json.load(f)
                    self.exercises = data.get('exercises', {})
                    self.start_time = data.get('start_time')
            except (json.JSONDecodeError, IOError):
                pass
    
    def save_session(self):
        """Save current workout session to file."""
        data = {
            'exercises': self.exercises,
            'start_time': self.start_time
        }
        try:
            with open(self.session_file, 'w') as f:
                json.dump(data, f, indent=2)
        except IOError as e:
            print(f"! Warning: Could not save session: {e}")
            print("  Your progress may not be saved.")
    
    def start_workout(self):
        """Start a new workout session."""
        self.exercises = {}
        self.start_time = datetime.now().isoformat()
        self.save_session()
        print("✓ New workout session started!")
        print(f"  Started at: {datetime.fromisoformat(self.start_time).strftime('%I:%M %p')}")
    
    def add_set(self, exercise: str, reps: int):
        """Add a set with specified reps to an exercise."""
        if not self.start_time:
            print("! Please start a workout session first with 'start'")
            return
        
        if exercise not in self.exercises:
            self.exercises[exercise] = []
        
        self.exercises[exercise].append(reps)
        set_number = len(self.exercises[exercise])
        self.save_session()
        
        print(f"✓ {exercise}: Set {set_number} - {reps} reps logged")
        self._show_exercise_summary(exercise)
    
    def _show_exercise_summary(self, exercise: str):
        """Show summary for a specific exercise."""
        sets = self.exercises.get(exercise, [])
        if sets:
            total_reps = sum(sets)
            print(f"  Total: {len(sets)} sets, {total_reps} reps")
    
    def show_progress(self):
        """Display current workout progress."""
        if not self.start_time:
            print("No active workout session.")
            print("Start a new workout with: repcount start")
            return
        
        print("\n" + "="*50)
        print("CURRENT WORKOUT SESSION")
        print("="*50)
        print(f"Started: {datetime.fromisoformat(self.start_time).strftime('%I:%M %p')}")
        print()
        
        if not self.exercises:
            print("No exercises logged yet.")
            print("Add a set with: repcount add <exercise> <reps>")
        else:
            for exercise, sets in self.exercises.items():
                total_reps = sum(sets)
                print(f"{exercise}:")
                for i, reps in enumerate(sets, 1):
                    print(f"  Set {i}: {reps} reps")
                print(f"  → Total: {len(sets)} sets, {total_reps} reps")
                print()
        
        print("="*50)
    
    def complete_workout(self):
        """Complete and save the workout session."""
        if not self.start_time:
            print("No active workout session to complete.")
            return
        
        # Save to history
        history_file = "workout_history.json"
        history = []
        
        if os.path.exists(history_file):
            try:
                with open(history_file, 'r') as f:
                    history = json.load(f)
            except (json.JSONDecodeError, IOError):
                pass
        
        workout_data = {
            'start_time': self.start_time,
            'end_time': datetime.now().isoformat(),
            'exercises': self.exercises
        }
        history.append(workout_data)
        
        try:
            with open(history_file, 'w') as f:
                json.dump(history, f, indent=2)
        except IOError as e:
            print(f"! Error: Could not save workout to history: {e}")
            print("  Your workout data may be lost.")
            return
        
        # Remove current session file
        if os.path.exists(self.session_file):
            os.remove(self.session_file)
        
        print("\n✓ Workout completed and saved to history!")
        self._show_workout_summary(workout_data)
    
    def _show_workout_summary(self, workout_data: dict):
        """Show summary of completed workout."""
        print("\nWorkout Summary:")
        total_sets = 0
        total_reps = 0
        
        for exercise, sets in workout_data['exercises'].items():
            exercise_reps = sum(sets)
            total_sets += len(sets)
            total_reps += exercise_reps
            print(f"  {exercise}: {len(sets)} sets, {exercise_reps} reps")
        
        print(f"\nOverall: {total_sets} total sets, {total_reps} total reps")
        
        start = datetime.fromisoformat(workout_data['start_time'])
        end = datetime.fromisoformat(workout_data['end_time'])
        duration = end - start
        minutes = int(duration.total_seconds() / 60)
        print(f"Duration: {minutes} minutes")


def print_usage():
    """Print usage instructions."""
    print("""
RepCount - Workout Set & Rep Counter
=====================================

Usage:
  repcount start                    Start a new workout session
  repcount add <exercise> <reps>    Log a set (e.g., repcount add pushups 15)
  repcount status                   View current workout progress
  repcount done                     Complete and save workout

Examples:
  repcount start
  repcount add pushups 20
  repcount add pushups 18
  repcount add squats 15
  repcount status
  repcount done
""")


def main():
    """Main entry point for the RepCount CLI."""
    session = WorkoutSession()
    
    if len(sys.argv) < 2:
        print_usage()
        return
    
    command = sys.argv[1].lower()
    
    if command == "start":
        session.start_workout()
    
    elif command == "add":
        if len(sys.argv) < 4:
            print("Error: Please specify exercise and reps")
            print("Usage: repcount add <exercise> <reps>")
            return
        
        exercise = sys.argv[2]
        try:
            reps = int(sys.argv[3])
            # Reps must be positive (at least 1)
            if reps <= 0:
                print("Error: Reps must be a positive number")
                return
            session.add_set(exercise, reps)
        except ValueError:
            print("Error: Reps must be a number")
    
    elif command in ["status", "show", "progress"]:
        session.show_progress()
    
    elif command in ["done", "complete", "finish"]:
        session.complete_workout()
    
    elif command in ["help", "-h", "--help"]:
        print_usage()
    
    else:
        print(f"Unknown command: {command}")
        print_usage()


if __name__ == "__main__":
    main()
