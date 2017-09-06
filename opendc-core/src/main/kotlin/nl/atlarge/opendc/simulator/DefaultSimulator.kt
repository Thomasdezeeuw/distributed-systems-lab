/*
 * MIT License
 *
 * Copyright (c) 2017 atlarge-research
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

package nl.atlarge.opendc.simulator

import mu.KotlinLogging
import nl.atlarge.opendc.simulator.clock.Clock
import nl.atlarge.opendc.simulator.clock.Tick
import nl.atlarge.opendc.simulator.messaging.Envelope
import nl.atlarge.opendc.topology.*
import java.util.*
import kotlin.coroutines.experimental.*

/**
 * A [DefaultSimulator] runs the simulation over the specified topology.
 *
 * @param topology The topology to run the simulation over.
 * @author Fabian Mastenbroek (f.s.mastenbroek@student.tudelft.nl)
 */
class DefaultSimulator(override val topology: Topology): Simulator, Iterator<Unit> {
	/**
	 * The logger instance to use for the simulator.
	 */
	private val logger = KotlinLogging.logger {}

	/**
	 * The registry of the simulation kernels used in the experiment.
	 */
	private val registry: MutableMap<Component<*>, Context<*>?> = HashMap()

	/**
	 * A mapping of the entities in the topology to their current state.
	 */
	private val states: MutableMap<Entity<*>, Any?> = HashMap()

	/**
	 * The clock of the simulator.
	 */
	private val clock: DefaultClock = DefaultClock()

	/**
	 * Initialize the simulator.
	 */
	init {
		topology.forEach { node ->
			resolve(node)
			node.outgoingEdges().forEach { resolve(it) }
		}

		registry.values.forEach { context ->
			if (context == null)
				return@forEach
			@Suppress("UNCHECKED_CAST")
			val kernel = context.component.label as Kernel<Context<*>>

			// Start all kernel co-routines
			val block: suspend () -> Unit = { kernel.run { context.simulate() } }
			block.startCoroutine(KernelCoroutine())
		}
	}

	/**
	 * Resolve the given [Component] to the [Kernel] of that component.
	 *
	 * @param component The component to resolve.
	 * @return The [Kernel] that simulates that [Component].
	 */
	fun <T: Component<*>> resolve(component: T): Context<T>? {
		@Suppress("UNCHECKED_CAST")
		return registry.computeIfAbsent(component, {
			if (component.label !is Kernel<*>)
				null
			else when (component) {
				is Node<*> -> DefaultEntityContext(component as Node<*>)
				is Edge<*> -> DefaultChannelContext(component as Edge<*>)
				else -> null
			}
		}) as Context<T>?
	}

	/**
	 * Determine whether the simulator has a next non-empty cycle available.
	 *
	 * @return <code>true</code> if the simulator has a next non-empty cycle, <code>false</code> otherwise.
	 */
	override fun hasNext(): Boolean = clock.queue.isNotEmpty()

	/**
	 * Run the next cycle in the simulation.
	 */
	override fun next() {
		clock.tick++
		while (true) {
			val (tick, block) = clock.queue.peek() ?: return

			if (tick > clock.tick)
				// Tick has yet to occur
				break
			else if (tick < clock.tick)
				// Tick has already occurred
				logger.warn {"tick was not handled correctly"}

			clock.queue.poll()
			block()
		}
	}

	/**
	 * The co-routine which runs a simulation kernel.
	 */
	private class KernelCoroutine: Continuation<Unit> {
		override val context: CoroutineContext = EmptyCoroutineContext
		override fun resume(value: Unit) {}

		override fun resumeWithException(exception: Throwable) {
			val currentThread = Thread.currentThread()
			currentThread.uncaughtExceptionHandler.uncaughtException(currentThread, exception)
		}
	}

	/**
	 * The [Context] for an entity within the simulation.
	 */
	private inner class DefaultEntityContext<out T: Entity<*>>(override val component: Node<T>): EntityContext<T> {
		/**
         * The [Topology] over which the simulation is run.
         */
		override val topology: Topology = this@DefaultSimulator.topology

		/**
         * Retrieves and removes a single message from this channel suspending the caller while the channel is empty.
         *
         * @param block The block to process the message with.
         * @return The processed message.
         */
		suspend override fun <T> receive(block: Envelope<*>.(Any?) -> T): T = suspendCoroutine {}

		/**
		 * The observable state of an [Entity] within the simulation is provided by context.
		 */
		@Suppress("UNCHECKED_CAST")
		override val <S> Entity<S>.state: S
			get() = states.computeIfAbsent(this, { initialState }) as S

		/**
         * Update the state of the entity being simulated.
         *
         * <p>Instead of directly mutating the entity, we create a new instance of the entity to prevent other objects
         * referencing the old entity having their data changed.
         *
         * @param next The next state of the entity.
         */
		suspend override fun <C: EntityContext<E>, E: Entity<S>, S> C.update(next: S) {
			states.put(component.entity as Entity<*>, next)
		}

		/**
         * Suspend the simulation kernel for <code>n</code> ticks before resuming the execution.
         *
         * @param n The amount of ticks to suspend the simulation kernel.
         */
		suspend override fun wait(n: Int): Unit = suspendCoroutine { cont -> clock.scheduleAfter(n, { cont.resume(Unit) }) }
	}

	/**
	 * The [Context] for an edge within the simulation.
	 */
	private inner class DefaultChannelContext<out T>(override val component: Edge<T>): ChannelContext<T> {
		/**
		 * The [Topology] over which the simulation is run.
		 */
		override val topology: Topology = this@DefaultSimulator.topology

		/**
         * Retrieves and removes a single message from this channel suspending the caller while the channel is empty.
         *
         * @param block The block to process the message with.
         * @return The processed message.
         */
		suspend override fun <T> receive(block: Envelope<*>.(Any?) -> T): T = suspendCoroutine {}

		/**
         * Send the given message downstream.
         *
         * @param msg The message to send.
         * @param sender The sender of the message.
         */
		suspend override fun send(msg: Any?, sender: Node<*>): Unit = suspendCoroutine {}

		/**
		 * The observable state of an [Entity] within the simulation is provided by context.
		 */
		@Suppress("UNCHECKED_CAST")
		override val <S> Entity<S>.state: S
			get() = states.computeIfAbsent(this, { initialState }) as S

		/**
		 * Suspend the simulation kernel for <code>n</code> ticks before resuming the execution.
		 *
		 * @param n The amount of ticks to suspend the simulation kernel.
		 */
		suspend override fun wait(n: Int): Unit = suspendCoroutine { cont -> clock.scheduleAfter(n, { cont.resume(Unit) }) }
	}

	/**
	 * The [Clock] for this [DefaultSimulator] that keeps track of the simulation time in ticks.
	 */
	private inner class DefaultClock: Clock {
		override var tick: Tick = 0
		internal val queue: PriorityQueue<Pair<Tick, () -> Unit>> = PriorityQueue(Comparator.comparingLong { it.first })

		override fun scheduleAt(tick: Tick, block: () -> Unit) {
			queue.add(Pair(tick, block))
		}
	}
}