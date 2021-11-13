//  
//  TodoWorkflow.swift
//  WorkflowTodo
//
//  Created by Fumiya Yamanaka on 2021/11/13.
//

import SwiftUI
import Workflow
import WorkflowSwiftUI

struct Task: Identifiable, Equatable {
  let id: UUID = UUID()
  let body: String
  var isCompleted: Bool = false
}

struct TodoListView: View {

  @State var tmpText: String = ""

  var body: some View {
    WorkflowView(
      workflow: TodoWorkflow(),
      onOutput: { output in
        switch output {
        case .addedTask:
          tmpText = ""
        }
      },
      content: { rendering in
        NavigationView {
          VStack {
            List {
              ForEach(rendering.tasks) { task in
                HStack {
                  Image(systemName: task.isCompleted ? "checkmark.square": "square")
                    .onTapGesture { rendering.toggleCompleted(task) }
                  Text(task.body)
                }
              }
              .onDelete { rendering.deleteTask($0) }
            }
            .listStyle(PlainListStyle())
            Spacer()
            HStack {
              TextField("Input task description", text: $tmpText)
              Button(
                action: { rendering.addTask(.init(body: tmpText)) },
                label: { Image(systemName: "paperplane.fill")}
              )
                .disabled(tmpText.isEmpty)
            }
            .padding()
          }
          .navigationTitle("Todo List")
        }
      })
  }
}

// MARK: Input and Output

struct TodoWorkflow: Workflow {
  enum Output {
    case addedTask
  }
}

// MARK: State and Initialization

extension TodoWorkflow {
  typealias State = [Task]

  func makeInitialState() -> TodoWorkflow.State {
    return []
  }

  func workflowDidChange(from previousWorkflow: TodoWorkflow, state: inout State) {}
}

// MARK: Actions

extension TodoWorkflow {
  enum Action: WorkflowAction {
    case addTask(Task)
    case deleteTask(IndexSet)
    case toggleCompleted(Task)

    typealias WorkflowType = TodoWorkflow

    func apply(toState state: inout TodoWorkflow.State) -> TodoWorkflow.Output? {
      switch self {
      case let .addTask(task):
        state.append(task)
        return .addedTask
      case let .deleteTask(indexSet):
        guard let first = indexSet.first else { return nil }
        state.remove(at: first)
      case let .toggleCompleted(task):
        guard let index = state.firstIndex(of: task) else { return nil }
        state[index].isCompleted.toggle()
      }
      return nil
    }
  }
}

// MARK: Rendering

extension TodoWorkflow {

  struct Rendering {
    var tasks: [Task]
    var addTask: (Task) -> Void
    var deleteTask: (IndexSet) -> Void
    var toggleCompleted: (Task) -> Void
  }

  func render(state: TodoWorkflow.State, context: RenderContext<TodoWorkflow>) -> Rendering {
    let sink = context.makeSink(of: Action.self)
    return Rendering(
      tasks: state,
      addTask: { sink.send(.addTask($0)) },
      deleteTask: { sink.send(.deleteTask($0)) },
      toggleCompleted: { sink.send(.toggleCompleted($0) )}
    )
  }
}
