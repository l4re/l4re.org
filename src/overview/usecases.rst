Use Cases
*********

.. todo::

    - Use https://www.kernkonzept.com/industries/

The following gives a glimpse in which domains and industries L4Re provides
security, safety and virtualization features.

Safety and Mixed Criticality Systems
------------------------------------

Safety systems need to guarantee Freedom from Interference both in the spatial
and the temporal domain. Due to the microkernel architecture of L4Re the small
code footprint of safety-critical parts of the system is particularly well
suited for certification in safety critical domains, for example to provide
mixed criticality systems hosting ASIL and QM workloads on the same system.
Specific configurations of L4Re have been certified as a safety element out of
context (SEooC) up to ISO26262 ASIL-B and SIL-2.

High Assurance Systems
----------------------

High Assurance Security IT systems are used in critical domains such as
government, public authorities, defense and public infrastructure (in Germany: KRITIS). To
protect classified information the highest security standards must be used to
safe-guard the assets. With its minimal trusted computing base the L4Re
Operating System Framework provides strong isolation to prevent leakage of
unauthorized access, data leakage, and cross-contamination between security
domains, thereby enabling the implementation of multi-level high security
architectures.

Secure Cloud Infrastructure
---------------------------

Hosting services in cloud infrastructure provides cost and scalability
benefits. Handling classified data in such an environment poses additional
requirements on the integrity and confidentiality of the service provider,
though. The L4Re Operating System Framework provides the foundation on which
such systems can be built and certified according to the applicable country
specific standards (e.g. Germany’s BSI), the EU and NATO.
