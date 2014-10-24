                                #################################################################################
                                #########################                               #########################
                                #########################       MORE ABOUT "DEWEY"      ######################### 
                                #########################                               #########################
                                #################################################################################


("Still in progress....")



Here are a few advices to use "dewey" on a right way. 

Dewey is a bash script able to manage WMS jobs. 

For now, "dewey" is only designed to deal with production stuffs. You can see how to launch a job in having a look at the config files you have to edit (wmsjob.sh, run_wms.zsh and your config.py - here prod_GENtoRECO.py). Well, basically, you just have to precise your "username", the place where the script has to look for your "input files", where you want to store the "output files", with what "config.py file". For now, dewey is built to deal with production stuffs. It means that it requires a specific syntax for your "input files" (with numbers). 

It would be pretty easy to write a script to help dewey to handle more kind of input files. Anyway, you just need to edit the "wmsjob.sh" and the "run_wms.zsh" and launch your jobs in doing "./run_mws.zsh". Please create a proxy just before launching some jobs and do not launch too many jobs at the samed time (<100).

When your jobs are submitted, you can use "dewey": 

                First, copy "dewey.sh" in your ~/tools/ and put an alias on "dewey" ( alias dewey="~/tools/dewey.sh" ) so you can use dewey everywhere. 

                dewey -S : Get the current status of all your jobs splitted by collections

                dewey -E : Dump the error that occured when a job failed

                dewey -R : Resubmit all failed jobs

If you want to know more about your collections, you can use "glite-wms-job-status URLofTheCollection". You will find "URLofTheCollection" in your jobs.txt file. 

If you want to know more about a single job, you can use "glite-wms-job-status URLofTheJob". You will find "URLofTheJob" when doing the previous point. 

There is for now no other tool but "cancel.zsh" to cancel/erase a collection. 
