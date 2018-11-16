\documentclass{scrartcl}

% TODO: better title?
\title{A deep analysis of different allocation policies}
\subtitle{Distributed Systems -- Lab exercise}
\author{Jan Haenen \and Kim van Putten \and Ruben Stam \and Thomas de Zeeuw}
% TODO: add email to all authors.
% TODO: add support cast (Lab supervisor and course instructors).

\date{December 20th 2018}

\begin{document}

\maketitle

\begin{abstract}

TODO: Abstract: a description of the problem, system description, analysis
overview, and one main result. Size: one paragraph with at most 150 words.

\end{abstract}



\section{Introduction} \label{sec_introduction}

TODO: Introduction (recommended size, including points 1 and 2: 1 page): describe
the problem, the existing systems and/or tools about which you know (related
work), the system or components you are about to implement, and the structure of
the remainder of the article. Use one short paragraph for each.



\section{Background} \label{sec_background}

TODO: Background on Application (recommended size: 0.5 pages): describe the
application (1 paragraph) and its requirements.



\section{System Design} \label{sec_system_design}

TODO: System Design (recommended size: 1.5 pages).


\subsection{System overview} \label{sec_system_overview}

TODO: System overview: describe the design of your system, including the system
components (which correspond to the homonym features required by the
WantScheduler CTO).


\subsection{Additional System Features} \label{sec_system_features}

TODO: (Optional, for bonus points, see Section G) Additional System Features:
describe each additional feature of your system, one sub-section per feature.



\section{Experimental Results} \label{sec_results}

TODO: Experimental Results (recommended size: 1.5 pages).


\subsection{Experimental Setup} \label{sec_setup}

TODO: Experimental setup: describe the working environments (DAS-4/5, Amazon
EC2, etc.), the general workload and monitoring tools and libraries, other tools
and libraries you have used to implement and deploy your system, other tools and
libraries used to conduct your experiments.


\subsection{Experiments} \label{sec_experiments}

TODO: Experiments: describe the experiments you have conducted to analyze each
	  system feature, such as consistency, scalability, fault-tolerance, and
	  performance. Analyze the results obtained for each system feature. Use one
	  sub-section per experiment (or feature). In the analysis, also report:
        i.   Service metrics of the experiment, such as runtime and response time of the
             service, etc.
        ii.  Usage metrics and, optionally, costs of the experiment.
        iii. The interpretation of the results; were they expected and what do
             the results mean?



\section{Discussion} \label{sec_discussion}

TODO: Discussion (recommended size: 1 page): summarize the main findings of your
work and discuss the tradeoffs inherent in the design of the system. Which
policy should WantScheduler use, and why? Try to extrapolate from the results
reported in Section 6.b for system workloads that are orders of magnitude higher
than what you have tried in real-world experiments.



\section{Conclusion} \label{sec_conclusion}

TODO: conclusion.


\appendix


\section{Appendix}

TODO: Appendix A: Time sheets (see Section F of assignment).

% TODO: add bibliography.

\end{document}
