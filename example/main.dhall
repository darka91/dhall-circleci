let dhall-circle = ../schema/circleci.dhall

let Executor = dhall-circle.Executor

let Orb = dhall-circle.Orb

let Step = dhall-circle.Step

let Job = dhall-circle.Job

let Workflow = dhall-circle.Workflow

let orbs =
      { slack = Orb.orb "circleci/slack@3.4.1"
      , aws-cli = Orb.orb "circleci/aws-cli@1.0.0"
      , expiration = Orb.orb "azihsoyn/job-expiration@0.1.0"
      }

let executors =
      { terraform = Executor.docker "terraform" "hashicorp/terraform"
      , ubuntu = Executor.machine "ubuntu" "ubuntu-1604:201903-01"
      }

let jobs =
      { job1 =
          Job.job
            "Job1-name"
            { executor = Job.executorInline executors.terraform
            , steps =
              [ Step.checkout
              , Step.attachWorkspaceAt "/"
              , Step.storeTestResultsFrom "./test-result.xml"
              , Step.run
                  { command =
                      ''
                      command here
                      ''
                  , name = "Run sample step"
                  }
              , Step.persistToWorkspace "/" [ "file1.txt", "file2.txt" ]
              , Step.step
                  { name = "custom step"
                  , parameters = toMap { param1 = "123", param2 = "321" }
                  }
              ]
            }
      , job2 =
          Job.job
            "Job2-name"
            { executor = Job.executorReference executors.ubuntu
            , steps =
              [ Step.attachWorkspaceAt "~/sample"
              , Step.step
                  { name = "custom step"
                  , parameters = toMap { param1 = "123", param2 = "321" }
                  }
              ]
            }
      }

let wf_job1 =
      Workflow.job { job = jobs.job1, requires = Workflow.noRequirements }

let wf_job2 = Workflow.job { job = jobs.job2, requires = [ wf_job1 ] }

let workflows =
      { workflow_1 = [ wf_job1, wf_job2 ]
      , workflow_2 = [ wf_job1 ]
      , workflow_3 = [ wf_job2 ]
      }

in  { configSample1 =
        dhall-circle.buildConfiguration
          { orbs = Some (toMap orbs)
          , executors = Some (toMap executors)
          , jobs = toMap jobs
          , workflows = toMap workflows
          }
    , configSample2 =
        dhall-circle.buildConfiguration
          { orbs = Orb.empty
          , executors = Executor.empty
          , jobs = toMap jobs
          , workflows = toMap workflows
          }
    }
